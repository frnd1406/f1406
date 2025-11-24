package middleware

import (
	"github.com/gin-gonic/gin"
)

// SecurityHeaders middleware adds security headers to all responses
// Protects against XSS, Clickjacking, MIME sniffing, etc.
func SecurityHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Strict-Transport-Security: force HTTPS (1 year)
		c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")

		// X-Frame-Options: block framing (clickjacking)
		c.Header("X-Frame-Options", "DENY")

		// X-Content-Type-Options: disable MIME sniffing
		c.Header("X-Content-Type-Options", "nosniff")

		// Referrer-Policy: reduce referrer leakage
		c.Header("Referrer-Policy", "strict-origin-when-cross-origin")

		c.Next()
	}
}
