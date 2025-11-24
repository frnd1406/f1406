package services

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/nas-ai/api/src/database"
	"github.com/sirupsen/logrus"
)

// TokenService handles verification and reset tokens
type TokenService struct {
	redis  *database.RedisClient
	logger *logrus.Logger
}

// NewTokenService creates a new token service
func NewTokenService(redis *database.RedisClient, logger *logrus.Logger) *TokenService {
	return &TokenService{
		redis:  redis,
		logger: logger,
	}
}

// GenerateVerificationToken generates a 32-byte random token for email verification
func (s *TokenService) GenerateVerificationToken(ctx context.Context, userID string) (string, error) {
	token, err := s.generateRandomToken()
	if err != nil {
		return "", err
	}

	// Store in Redis with 24-hour expiry
	key := "verify:" + token
	if err := s.redis.Set(ctx, key, userID, 24*time.Hour).Err(); err != nil {
		s.logger.WithError(err).Error("Failed to store verification token")
		return "", fmt.Errorf("failed to store verification token: %w", err)
	}

	s.logger.WithFields(logrus.Fields{
		"user_id": userID,
		"token":   token[:8] + "...", // Log only first 8 chars
	}).Debug("Verification token generated")

	return token, nil
}

// ValidateVerificationToken validates and consumes a verification token
func (s *TokenService) ValidateVerificationToken(ctx context.Context, token string) (string, error) {
	key := "verify:" + token
	userID, err := s.redis.Get(ctx, key).Result()
	if err != nil {
		s.logger.WithError(err).Debug("Verification token not found or expired")
		return "", fmt.Errorf("invalid or expired token")
	}

	// Delete token (single-use)
	if err := s.redis.Del(ctx, key).Err(); err != nil {
		s.logger.WithError(err).Warn("Failed to delete verification token")
	}

	s.logger.WithField("user_id", userID).Info("Verification token validated")
	return userID, nil
}

// GeneratePasswordResetToken generates a 32-byte random token for password reset
func (s *TokenService) GeneratePasswordResetToken(ctx context.Context, userID string) (string, error) {
	token, err := s.generateRandomToken()
	if err != nil {
		return "", err
	}

	// Store in Redis with 1-hour expiry
	key := "reset:" + token
	if err := s.redis.Set(ctx, key, userID, 1*time.Hour).Err(); err != nil {
		s.logger.WithError(err).Error("Failed to store password reset token")
		return "", fmt.Errorf("failed to store password reset token: %w", err)
	}

	s.logger.WithFields(logrus.Fields{
		"user_id": userID,
		"token":   token[:8] + "...", // Log only first 8 chars
	}).Debug("Password reset token generated")

	return token, nil
}

// ValidatePasswordResetToken validates and consumes a password reset token
func (s *TokenService) ValidatePasswordResetToken(ctx context.Context, token string) (string, error) {
	key := "reset:" + token
	userID, err := s.redis.Get(ctx, key).Result()
	if err != nil {
		s.logger.WithError(err).Debug("Password reset token not found or expired")
		return "", fmt.Errorf("invalid or expired token")
	}

	// Delete token (single-use)
	if err := s.redis.Del(ctx, key).Err(); err != nil {
		s.logger.WithError(err).Warn("Failed to delete password reset token")
	}

	s.logger.WithField("user_id", userID).Info("Password reset token validated")
	return userID, nil
}

// generateRandomToken generates a 32-byte random token
func (s *TokenService) generateRandomToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", fmt.Errorf("failed to generate random token: %w", err)
	}
	return base64.URLEncoding.EncodeToString(b), nil
}
