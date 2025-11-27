package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// BackupHandler handles PUT /api/v1/system/settings/backup
// Description: Backup Settings
func BackupHandler(logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// TODO: Implementiere deine Logik hier

		// Beispiel: GET-Request
		if c.Request.Method == "GET" {
			c.JSON(http.StatusOK, gin.H{
				"message": "Backup Settings",
				"data":    []string{},
			})
			return
		}

		// Beispiel: POST-Request
		if c.Request.Method == "POST" {
			var payload map[string]interface{}
			if err := c.ShouldBindJSON(&payload); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "invalid payload"})
				return
			}

			c.JSON(http.StatusCreated, gin.H{
				"message": "created successfully",
				"data":    payload,
			})
			return
		}

		c.JSON(http.StatusMethodNotAllowed, gin.H{"error": "method not allowed"})
	}
}
