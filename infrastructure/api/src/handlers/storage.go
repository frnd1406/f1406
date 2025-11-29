package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/services"
	"github.com/sirupsen/logrus"
)

func handleStorageError(c *gin.Context, err error, logger *logrus.Logger, requestID string) {
	status := http.StatusBadRequest
	message := "storage operation failed"

	// Map specific errors to appropriate HTTP status codes and messages
	if errors.Is(err, services.ErrPathTraversal) {
		status = http.StatusForbidden
		message = "access denied: path traversal detected"
	} else if errors.Is(err, services.ErrInvalidFileType) {
		status = http.StatusBadRequest
		message = "invalid file type: only images, documents, videos, and archives are allowed"
	} else if errors.Is(err, services.ErrFileTooLarge) {
		status = http.StatusBadRequest
		message = "file too large: maximum upload size is 100MB"
	} else if os.IsNotExist(err) {
		status = http.StatusNotFound
		message = "file or directory not found"
	}

	logger.WithFields(logrus.Fields{
		"request_id": requestID,
		"error":      err.Error(),
		"status":     status,
	}).Warn("storage: request failed")

	c.JSON(status, gin.H{
		"error": gin.H{
			"code":       "storage_error",
			"message":    message,
			"request_id": requestID,
		},
	})
}

type renameRequest struct {
	OldPath string `json:"oldPath" binding:"required"`
	NewName string `json:"newName" binding:"required"`
}

func StorageListHandler(storage *services.StorageService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")
		path := c.Query("path")

		items, err := storage.List(path)
		if err != nil {
			handleStorageError(c, err, logger, requestID)
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"items": items,
		})
	}
}

func StorageUploadHandler(storage *services.StorageService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")
		path := c.PostForm("path")

		fileHeader, err := c.FormFile("file")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "file is required"})
			return
		}

		src, err := fileHeader.Open()
		if err != nil {
			logger.WithFields(logrus.Fields{
				"request_id": requestID,
				"error":      err.Error(),
			}).Error("storage: open upload file failed")
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to read upload"})
			return
		}
		defer src.Close()

		if err := storage.Save(path, src, fileHeader.Filename); err != nil {
			handleStorageError(c, err, logger, requestID)
			return
		}

		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	}
}

func StorageDownloadHandler(storage *services.StorageService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")
		path := c.Query("path")
		if path == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "path is required"})
			return
		}

		file, info, ctype, err := storage.Open(path)
		if err != nil {
			handleStorageError(c, err, logger, requestID)
			return
		}
		defer file.Close()

		c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=\"%s\"", info.Name()))
		c.DataFromReader(http.StatusOK, info.Size(), ctype, file, nil)
	}
}

func StorageDeleteHandler(storage *services.StorageService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")
		path := c.Query("path")
		if path == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "path is required"})
			return
		}

		if err := storage.Delete(path); err != nil {
			handleStorageError(c, err, logger, requestID)
			return
		}

		c.JSON(http.StatusOK, gin.H{"status": "deleted"})
	}
}

func StorageTrashListHandler(storage *services.StorageService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")
		items, err := storage.ListTrash()
		if err != nil {
			handleStorageError(c, err, logger, requestID)
			return
		}
		c.JSON(http.StatusOK, gin.H{"items": items})
	}
}

func StorageTrashRestoreHandler(storage *services.StorageService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "id is required"})
			return
		}
		if err := storage.RestoreFromTrash(filepath.ToSlash(id)); err != nil {
			handleStorageError(c, err, logger, requestID)
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "restored"})
	}
}

func StorageTrashDeleteHandler(storage *services.StorageService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "id is required"})
			return
		}
		if err := storage.DeleteFromTrash(filepath.ToSlash(id)); err != nil {
			handleStorageError(c, err, logger, requestID)
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "deleted"})
	}
}

func StorageRenameHandler(storage *services.StorageService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")
		var req renameRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload"})
			return
		}
		if err := storage.Rename(req.OldPath, req.NewName); err != nil {
			handleStorageError(c, err, logger, requestID)
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "renamed"})
	}
}
