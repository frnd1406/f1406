package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/config"
	"github.com/sirupsen/logrus"
)

// CORS middleware handles Cross-Origin Resource Sharing with an allowlist.
func CORS(cfg *config.Config, logger *logrus.Logger) gin.HandlerFunc {
	allowed := make(map[string]struct{})
	for _, o := range cfg.CORSOrigins {
		allowed[strings.TrimSpace(o)] = struct{}{}
	}

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if origin != "" {
			if _, ok := allowed[origin]; ok {
				c.Header("Access-Control-Allow-Origin", origin)
				c.Header("Vary", "Origin")
				c.Header("Access-Control-Allow-Credentials", "true")
				c.Header("Access-Control-Allow-Headers", "Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization, accept, origin, Cache-Control, X-Requested-With")
				c.Header("Access-Control-Allow-Methods", "POST, OPTIONS, GET, PUT, DELETE, PATCH")
				c.Header("Access-Control-Max-Age", "86400") // 24 hours
			} else {
				logger.WithField("origin", origin).Debug("CORS origin not allowed")
			}
		}

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}
