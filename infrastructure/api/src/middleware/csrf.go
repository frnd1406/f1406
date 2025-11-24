package middleware

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/database"
	"github.com/sirupsen/logrus"
)

// CSRFMiddleware validates CSRF tokens for state-changing requests
func CSRFMiddleware(redis *database.RedisClient, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")

		// Only validate CSRF for POST, PUT, DELETE, PATCH
		if c.Request.Method == "GET" || c.Request.Method == "HEAD" || c.Request.Method == "OPTIONS" {
			c.Next()
			return
		}

		// Extract CSRF token from header
		csrfToken := c.GetHeader("X-CSRF-Token")
		if csrfToken == "" {
			logger.WithField("request_id", requestID).Warn("Missing CSRF token")
			c.JSON(http.StatusForbidden, gin.H{
				"error": gin.H{
					"code":       "csrf_token_missing",
					"message":    "CSRF token is required",
					"request_id": requestID,
				},
			})
			c.Abort()
			return
		}

		// Get user_id from context (set by auth middleware)
		userID, exists := c.Get("user_id")
		if !exists {
			logger.WithField("request_id", requestID).Error("CSRF check failed: no user_id in context")
			c.JSON(http.StatusForbidden, gin.H{
				"error": gin.H{
					"code":       "csrf_validation_failed",
					"message":    "Invalid CSRF token",
					"request_id": requestID,
				},
			})
			c.Abort()
			return
		}

		// Validate CSRF token from Redis
		ctx := context.Background()
		key := "csrf:" + userID.(string)
		storedToken, err := redis.Get(ctx, key).Result()

		if err != nil || storedToken != csrfToken {
			logger.WithFields(logrus.Fields{
				"request_id": requestID,
				"user_id":    userID,
			}).Warn("Invalid CSRF token")
			c.JSON(http.StatusForbidden, gin.H{
				"error": gin.H{
					"code":       "csrf_validation_failed",
					"message":    "Invalid CSRF token",
					"request_id": requestID,
				},
			})
			c.Abort()
			return
		}

		logger.WithFields(logrus.Fields{
			"request_id": requestID,
			"user_id":    userID,
		}).Debug("CSRF token validated successfully")

		c.Next()
	}
}

// GenerateCSRFToken generates a new CSRF token for a user
func GenerateCSRFToken(redis *database.RedisClient, userID string) (string, error) {
	// Generate 32-byte random token
	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		return "", err
	}

	token := base64.URLEncoding.EncodeToString(tokenBytes)

	// Store in Redis with 24-hour expiry
	ctx := context.Background()
	key := "csrf:" + userID
	if err := redis.Set(ctx, key, token, 24*time.Hour).Err(); err != nil {
		return "", err
	}

	return token, nil
}
