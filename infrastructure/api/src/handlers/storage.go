package handlers

import (
	"fmt"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/nas-ai/api/src/services"
	"github.com/sirupsen/logrus"
)

func StorageListHandler(storage *services.StorageService, logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetString("request_id")
		path := c.Query("path")

		items, err := storage.List(path)
		if err != nil {
			logger.WithFields(logrus.Fields{
				"request_id": requestID,
				"error":      err.Error(),
			}).Warn("storage: list failed")
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid path"})
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
			logger.WithFields(logrus.Fields{
				"request_id": requestID,
				"error":      err.Error(),
			}).Warn("storage: save failed")
			c.JSON(http.StatusBadRequest, gin.H{"error": "failed to store file"})
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
			status := http.StatusBadRequest
			if os.IsNotExist(err) {
				status = http.StatusNotFound
			}
			logger.WithFields(logrus.Fields{
				"request_id": requestID,
				"error":      err.Error(),
			}).Warn("storage: download failed")
			c.JSON(status, gin.H{"error": "file not found"})
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
			status := http.StatusBadRequest
			if os.IsNotExist(err) {
				status = http.StatusNotFound
			}
			logger.WithFields(logrus.Fields{
				"request_id": requestID,
				"error":      err.Error(),
			}).Warn("storage: delete failed")
			c.JSON(status, gin.H{"error": "delete failed"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"status": "deleted"})
	}
}
