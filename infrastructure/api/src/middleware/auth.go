package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/database"
	"github.com/nas-ai/api/src/services"
	"github.com/sirupsen/logrus"
)

// AuthMiddleware validates JWT tokens and checks blacklist
func AuthMiddleware(jwtService *services.JWTService, redis *database.RedisClient, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")

		// Extract token from Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			logger.WithField("request_id", requestID).Warn("Missing Authorization header")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"code":       "unauthorized",
					"message":    "Missing authorization token",
					"request_id": requestID,
				},
			})
			c.Abort()
			return
		}

		// Check Bearer token format
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			logger.WithField("request_id", requestID).Warn("Invalid Authorization header format")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"code":       "unauthorized",
					"message":    "Invalid authorization header format",
					"request_id": requestID,
				},
			})
			c.Abort()
			return
		}

		tokenString := parts[1]

		// Validate JWT token
		claims, err := jwtService.ValidateToken(tokenString)
		if err != nil {
			logger.WithFields(logrus.Fields{
				"request_id": requestID,
				"error":      err.Error(),
			}).Warn("Invalid JWT token")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"code":       "unauthorized",
					"message":    "Invalid or expired token",
					"request_id": requestID,
				},
			})
			c.Abort()
			return
		}

		// Check if token is blacklisted (logout revocation)
		ctx := context.Background()
		blacklisted, err := redis.Get(ctx, "blacklist:"+tokenString).Result()
		if err == nil && blacklisted == "1" {
			logger.WithFields(logrus.Fields{
				"request_id": requestID,
				"user_id":    claims.UserID,
			}).Warn("Blacklisted token used")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"code":       "unauthorized",
					"message":    "Token has been revoked",
					"request_id": requestID,
				},
			})
			c.Abort()
			return
		}

		// Store user info in context for handlers
		c.Set("user_id", claims.UserID)
		c.Set("user_email", claims.Email)

		logger.WithFields(logrus.Fields{
			"request_id": requestID,
			"user_id":    claims.UserID,
		}).Debug("User authenticated successfully")

		c.Next()
	}
}
