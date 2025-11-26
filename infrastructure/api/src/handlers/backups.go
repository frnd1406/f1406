package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/config"
	"github.com/nas-ai/api/src/services"
	"github.com/sirupsen/logrus"
)

func BackupListHandler(backupSvc *services.BackupService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		items, err := backupSvc.ListBackups()
		if err != nil {
			logger.WithError(err).Warn("backup: list failed")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to list backups"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"items": items})
	}
}

func BackupCreateHandler(backupSvc *services.BackupService, cfg *config.Config, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		b, err := backupSvc.CreateBackup(cfg.BackupStoragePath)
		if err != nil {
			logger.WithError(err).Warn("backup: create failed")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create backup"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"backup": b})
	}
}

func BackupRestoreHandler(backupSvc *services.BackupService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "id required"})
			return
		}
		if err := backupSvc.RestoreBackup(id); err != nil {
			logger.WithError(err).Warn("backup: restore failed")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to restore backup"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "restored", "id": id})
	}
}

func BackupDeleteHandler(backupSvc *services.BackupService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "id required"})
			return
		}
		if err := backupSvc.DeleteBackup(id); err != nil {
			logger.WithError(err).Warn("backup: delete failed")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete backup"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "deleted", "id": id})
	}
}
