package middleware

import (
	"log/slog"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/logger"
)

// SlogAuditLogger middleware logs all requests with structured logging using slog
// Implements audit trail for security compliance
// Format: JSON structured logging for ELK, Loki, Graylog aggregation
func SlogAuditLogger(slogLogger *slog.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Start timer
		start := time.Now()

		// Process request
		c.Next()

		// Calculate duration
		duration := time.Since(start)

		// Get request ID (set by RequestID middleware)
		requestID := c.GetString("request_id")

		// Get user ID (will be set by Auth middleware)
		userID := c.GetString("user_id")
		if userID == "" {
			userID = "anonymous"
		}

		// Extract request details
		method := c.Request.Method
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery
		status := c.Writer.Status()
		ip := c.ClientIP()
		userAgent := c.Request.UserAgent()
		bytesSent := c.Writer.Size()

		// Log the request
		logger.LogRequest(slogLogger, method, path, query, ip, userAgent, userID, requestID, status, duration, bytesSent)

		// Special audit logging for sensitive operations
		// (Auth endpoints, data modifications, etc.)
		if method != "GET" && method != "OPTIONS" && method != "HEAD" {
			logger.LogAudit(slogLogger, method, path, ip, userID, requestID, status)
		}
	}
}
