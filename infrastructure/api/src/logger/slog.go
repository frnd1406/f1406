package logger

import (
	"context"
	"log/slog"
	"os"
	"time"

	"github.com/gin-gonic/gin"
)

// NewSlogLogger creates a new structured logger using slog
// Supports JSON format for machine-readable logs (ELK, Loki, Graylog)
func NewSlogLogger(logLevel string, env string) *slog.Logger {
	// Parse log level
	level := parseLogLevel(logLevel)

	// Configure handler options
	opts := &slog.HandlerOptions{
		Level:     level,
		AddSource: env == "development", // Add source file info in dev
	}

	// Use JSON handler for production, text for development
	var handler slog.Handler
	if env == "production" || env == "staging" {
		handler = slog.NewJSONHandler(os.Stdout, opts)
	} else {
		handler = slog.NewTextHandler(os.Stdout, opts)
	}

	return slog.New(handler)
}

// parseLogLevel converts string log level to slog.Level
func parseLogLevel(logLevel string) slog.Level {
	switch logLevel {
	case "debug":
		return slog.LevelDebug
	case "info":
		return slog.LevelInfo
	case "warn":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}

// ContextWithLogger adds logger to context
func ContextWithLogger(ctx context.Context, logger *slog.Logger) context.Context {
	return context.WithValue(ctx, "logger", logger)
}

// LoggerFromContext retrieves logger from context
func LoggerFromContext(ctx context.Context) *slog.Logger {
	if logger, ok := ctx.Value("logger").(*slog.Logger); ok {
		return logger
	}
	return slog.Default()
}

// GinContextWithLogger adds logger with request context to Gin context
func GinContextWithLogger(c *gin.Context, logger *slog.Logger) *slog.Logger {
	requestID := c.GetString("request_id")
	userID := c.GetString("user_id")
	if userID == "" {
		userID = "anonymous"
	}

	return logger.With(
		slog.String("request_id", requestID),
		slog.String("user_id", userID),
		slog.String("method", c.Request.Method),
		slog.String("path", c.Request.URL.Path),
		slog.String("ip", c.ClientIP()),
	)
}

// LogRequest logs HTTP request with structured fields
func LogRequest(logger *slog.Logger, method, path, query, ip, userAgent, userID, requestID string, status int, duration time.Duration, bytesSent int) {
	level := slog.LevelInfo
	msg := "Request completed"

	// Set log level based on status code
	switch {
	case status >= 500:
		level = slog.LevelError
		msg = "Server error"
	case status >= 400:
		level = slog.LevelWarn
		msg = "Client error"
	case status >= 300:
		level = slog.LevelInfo
		msg = "Redirect"
	}

	logger.LogAttrs(context.Background(), level, msg,
		slog.String("request_id", requestID),
		slog.String("timestamp", time.Now().Format(time.RFC3339)),
		slog.String("method", method),
		slog.String("path", path),
		slog.String("query", query),
		slog.Int("status", status),
		slog.Int64("duration_ms", duration.Milliseconds()),
		slog.String("ip", ip),
		slog.String("user_agent", userAgent),
		slog.String("user_id", userID),
		slog.Int("bytes_sent", bytesSent),
	)
}

// LogAudit logs audit trail for sensitive operations
func LogAudit(logger *slog.Logger, method, path, ip, userID, requestID string, status int) {
	logger.LogAttrs(context.Background(), slog.LevelInfo, "AUDIT: Data modification request",
		slog.Bool("audit", true),
		slog.String("request_id", requestID),
		slog.String("user_id", userID),
		slog.String("method", method),
		slog.String("path", path),
		slog.String("ip", ip),
		slog.Int("status", status),
		slog.String("timestamp", time.Now().Format(time.RFC3339)),
	)
}

// LogError logs error with context
func LogError(logger *slog.Logger, msg string, err error, attrs ...slog.Attr) {
	logAttrs := []any{slog.String("error", err.Error())}
	for _, attr := range attrs {
		logAttrs = append(logAttrs, attr)
	}
	logger.Error(msg, logAttrs...)
}

// LogInfo logs info message with attributes
func LogInfo(logger *slog.Logger, msg string, attrs ...slog.Attr) {
	logAttrs := make([]any, len(attrs))
	for i, attr := range attrs {
		logAttrs[i] = attr
	}
	logger.Info(msg, logAttrs...)
}

// LogDebug logs debug message with attributes
func LogDebug(logger *slog.Logger, msg string, attrs ...slog.Attr) {
	logAttrs := make([]any, len(attrs))
	for i, attr := range attrs {
		logAttrs[i] = attr
	}
	logger.Debug(msg, logAttrs...)
}

// LogWarn logs warning message with attributes
func LogWarn(logger *slog.Logger, msg string, attrs ...slog.Attr) {
	logAttrs := make([]any, len(attrs))
	for i, attr := range attrs {
		logAttrs[i] = attr
	}
	logger.Warn(msg, logAttrs...)
}
