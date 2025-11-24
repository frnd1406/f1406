package handlers

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// HealthChecker is implemented by dependencies that can be probed.
type HealthChecker interface {
	HealthCheck(ctx context.Context) error
}

// Health godoc
// @Summary Health check endpoint
// @Description Returns API health status and dependency information
// @Tags System
// @Accept json
// @Produce json
// @Success 200 {object} map[string]interface{} "Health status information"
// @Failure 503 {object} map[string]interface{} "Dependency unavailable"
// @Router /health [get]
func Health(db HealthChecker, redis HealthChecker, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), 2*time.Second)
		defer cancel()

		dependencies := gin.H{}
		healthy := true

		if db == nil {
			logger.Error("PostgreSQL health check skipped: dependency not provided")
			dependencies["database"] = "unhealthy"
			healthy = false
		} else if err := db.HealthCheck(ctx); err != nil {
			logger.WithError(err).Error("PostgreSQL health check failed")
			dependencies["database"] = "unhealthy"
			healthy = false
		} else {
			dependencies["database"] = "ok"
		}

		if redis == nil {
			logger.Error("Redis health check skipped: dependency not provided")
			dependencies["redis"] = "unhealthy"
			healthy = false
		} else if err := redis.HealthCheck(ctx); err != nil {
			logger.WithError(err).Error("Redis health check failed")
			dependencies["redis"] = "unhealthy"
			healthy = false
		} else {
			dependencies["redis"] = "ok"
		}

		status := gin.H{
			"status":       "ok",
			"timestamp":    time.Now().Format(time.RFC3339),
			"service":      "nas-api",
			"version":      "1.0.0-phase1",
			"dependencies": dependencies,
		}

		if !healthy {
			status["status"] = "degraded"
			c.JSON(http.StatusServiceUnavailable, status)
			return
		}

		c.JSON(http.StatusOK, status)
	}
}
