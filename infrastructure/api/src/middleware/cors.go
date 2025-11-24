package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/config"
	"github.com/sirupsen/logrus"
)

// CORS middleware handles Cross-Origin Resource Sharing.
// Development override: Allow any origin so the UI can be reached via LAN IPs.
func CORS(cfg *config.Config, logger *logrus.Logger) gin.HandlerFunc {
	_ = cfg
	_ = logger

	return func(c *gin.Context) {
		// Open up CORS for development to allow LAN access.
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
		c.Header("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")
		c.Header("Access-Control-Max-Age", "86400") // 24 hours

		// Handle preflight OPTIONS requests
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
