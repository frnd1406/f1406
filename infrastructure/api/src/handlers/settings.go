package handlers

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/config"
	"github.com/nas-ai/api/src/scheduler"
	"github.com/nas-ai/api/src/services"
	"github.com/robfig/cron/v3"
	"github.com/sirupsen/logrus"
)

type BackupSettingsRequest struct {
	Schedule  string `json:"schedule" binding:"required"`
	Retention int    `json:"retention" binding:"required"`
	Path      string `json:"path" binding:"required"`
}

func SystemSettingsHandler(cfg *config.Config) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"backup": gin.H{
				"schedule":  cfg.BackupSchedule,
				"retention": cfg.BackupRetentionCount,
				"path":      cfg.BackupStoragePath,
			},
		})
	}
}

func UpdateBackupSettingsHandler(cfg *config.Config, backupSvc *services.BackupService, logger *logrus.Logger) gin.HandlerFunc {
	parser := cron.NewParser(cron.Minute | cron.Hour | cron.Dom | cron.Month | cron.Dow)

	return func(c *gin.Context) {
		var req BackupSettingsRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload"})
			return
		}

		req.Schedule = strings.TrimSpace(req.Schedule)
		req.Path = filepath.Clean(strings.TrimSpace(req.Path))

		if _, err := parser.Parse(req.Schedule); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid schedule format"})
			return
		}
		if req.Retention < 1 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "retention must be >= 1"})
			return
		}
		if req.Path == "" || req.Path == "." || req.Path == string(os.PathSeparator) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid backup path"})
			return
		}

		if err := backupSvc.SetBackupPath(req.Path); err != nil {
			logger.WithError(err).Warn("backup settings: failed to set backup path")
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		cfg.BackupSchedule = req.Schedule
		cfg.BackupRetentionCount = req.Retention
		cfg.BackupStoragePath = req.Path

		if err := scheduler.RestartScheduler(); err != nil {
			logger.WithError(err).Error("backup settings: failed to restart scheduler")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to restart scheduler"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"backup": gin.H{
				"schedule":  cfg.BackupSchedule,
				"retention": cfg.BackupRetentionCount,
				"path":      cfg.BackupStoragePath,
			},
		})
	}
}
