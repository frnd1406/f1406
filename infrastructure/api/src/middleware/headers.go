package middleware

import (
	"github.com/gin-gonic/gin"
)

// SecurityHeaders middleware adds security headers to all responses
// Protects against XSS, Clickjacking, MIME sniffing, etc.
func SecurityHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Prevent clickjacking
		c.Header("X-Frame-Options", "DENY")

		// Prevent MIME sniffing
		c.Header("X-Content-Type-Options", "nosniff")

		// XSS Protection (legacy, but still useful)
		c.Header("X-XSS-Protection", "1; mode=block")

		// HSTS - Force HTTPS (1 year + subdomains)
		// Note: Only set in production with actual HTTPS!
		if c.GetString("environment") == "production" {
			c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		}

		// Content Security Policy
		// Start restrictive, can be relaxed later
		c.Header("Content-Security-Policy", "default-src 'self'")

		// Referrer Policy
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")

		// Permissions Policy (disable unnecessary browser features)
		c.Header("Permissions-Policy", "geolocation=(), microphone=(), camera=()")

		c.Next()
	}
}
