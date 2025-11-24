package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/database"
	"github.com/nas-ai/api/src/middleware"
	"github.com/sirupsen/logrus"
)

// GetCSRFToken returns a CSRF token for the authenticated user
// @Summary Get CSRF Token
// @Description Returns a CSRF token for state-changing requests. Requires authentication.
// @Tags CSRF
// @Security BearerAuth
// @Produce json
// @Success 200 {object} map[string]string "CSRF token generated successfully"
// @Failure 401 {object} map[string]interface{} "Unauthorized"
// @Failure 500 {object} map[string]interface{} "Internal server error"
// @Router /auth/csrf [get]
func GetCSRFToken(redis *database.RedisClient, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")

		// Get user_id from context (set by auth middleware)
		userID, exists := c.Get("user_id")
		if !exists {
			logger.WithField("request_id", requestID).Error("No user_id in context")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": gin.H{
					"code":       "unauthorized",
					"message":    "Authentication required",
					"request_id": requestID,
				},
			})
			return
		}

		// Generate CSRF token
		token, err := middleware.GenerateCSRFToken(redis, userID.(string))
		if err != nil {
			logger.WithFields(logrus.Fields{
				"request_id": requestID,
				"user_id":    userID,
				"error":      err.Error(),
			}).Error("Failed to generate CSRF token")

			c.JSON(http.StatusInternalServerError, gin.H{
				"error": gin.H{
					"code":       "csrf_generation_failed",
					"message":    "Failed to generate CSRF token",
					"request_id": requestID,
				},
			})
			return
		}

		logger.WithFields(logrus.Fields{
			"request_id": requestID,
			"user_id":    userID,
		}).Info("CSRF token generated")

		c.JSON(http.StatusOK, gin.H{
			"csrf_token": token,
		})
	}
}
