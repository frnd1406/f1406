package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/services"
	"github.com/sirupsen/logrus"
)

func handleStorageError(c *gin.Context, err error, logger *logrus.Logger, requestID string) {
	status := http.StatusBadRequest
	if errors.Is(err, services.ErrPathTraversal) {
		status = http.StatusForbidden
	}
	if os.IsNotExist(err) {
		status = http.StatusNotFound
	}

	logger.WithFields(logrus.Fields{
		"request_id": requestID,
		"error":      err.Error(),
	}).Warn("storage: request failed")

	c.JSON(status, gin.H{"error": "storage operation failed"})
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
