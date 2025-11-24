package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/config"
	"golang.org/x/time/rate"
)

// RateLimiter middleware implements rate limiting per IP address
// Uses token bucket algorithm (sliding window)
// Phase 1: In-memory (Phase 2: Redis for distributed limiting)
type RateLimiter struct {
	limiters map[string]*rate.Limiter
	mu       sync.RWMutex
	rate     rate.Limit
	burst    int
}

// NewRateLimiter creates a new rate limiter
func NewRateLimiter(cfg *config.Config) *RateLimiter {
	// Convert requests/min to requests/second
	r := rate.Limit(float64(cfg.RateLimitPerMin) / 60.0)

	return &RateLimiter{
		limiters: make(map[string]*rate.Limiter),
		rate:     r,
		burst:    cfg.RateLimitPerMin, // Allow burst up to limit
	}
}

// getLimiter gets or creates limiter for IP
func (rl *RateLimiter) getLimiter(ip string) *rate.Limiter {
	rl.mu.RLock()
	limiter, exists := rl.limiters[ip]
	rl.mu.RUnlock()

	if exists {
		return limiter
	}

	// Create new limiter
	rl.mu.Lock()
	defer rl.mu.Unlock()

	// Double-check after acquiring write lock
	if limiter, exists := rl.limiters[ip]; exists {
		return limiter
	}

	limiter = rate.NewLimiter(rl.rate, rl.burst)
	rl.limiters[ip] = limiter

	// Cleanup old limiters (simple: every 100 new limiters)
	if len(rl.limiters) > 10000 {
		// Reset map (simple approach for Phase 1)
		rl.limiters = make(map[string]*rate.Limiter)
	}

	return limiter
}

// Middleware returns the rate limiting middleware
func (rl *RateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		limiter := rl.getLimiter(ip)

		if !limiter.Allow() {
			// Rate limit exceeded
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": gin.H{
					"code":    "rate_limit_exceeded",
					"message": "Too many requests. Please try again later.",
					"retry_after": time.Second * 60, // Suggest retry after 1 minute
				},
			})
			c.Abort()
			return
		}

		c.Next()
	}
}
