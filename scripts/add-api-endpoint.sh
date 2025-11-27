#!/bin/bash
set -e

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

API_DIR="/home/freun/Agent/infrastructure/api"

echo -e "${BLUE}=====================================================${NC}"
echo -e "${BLUE}     NAS.AI API Endpoint Generator${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""

# ==================================================
# SCHRITT 1: Informationen sammeln
# ==================================================
echo -e "${YELLOW}Schritt 1: Endpoint-Informationen${NC}"
echo ""

read -p "Endpoint-Name (z.B. 'tasks', 'notifications'): " ENDPOINT_NAME
ENDPOINT_NAME=$(echo "$ENDPOINT_NAME" | tr '[:upper:]' '[:lower:]')

read -p "HTTP Methode (GET/POST/PUT/DELETE): " HTTP_METHOD
HTTP_METHOD=$(echo "$HTTP_METHOD" | tr '[:lower:]' '[:upper:]')

read -p "Endpoint-Pfad (z.B. '/api/v1/tasks'): " ENDPOINT_PATH

read -p "Authentifizierung erforderlich? (y/n): " NEEDS_AUTH
NEEDS_AUTH=$(echo "$NEEDS_AUTH" | tr '[:upper:]' '[:lower:]')

read -p "Kurze Beschreibung: " DESCRIPTION

echo ""
echo -e "${GREEN}Zusammenfassung:${NC}"
echo -e "  Name:          ${ENDPOINT_NAME}"
echo -e "  Methode:       ${HTTP_METHOD}"
echo -e "  Pfad:          ${ENDPOINT_PATH}"
echo -e "  Auth:          ${NEEDS_AUTH}"
echo -e "  Beschreibung:  ${DESCRIPTION}"
echo ""

read -p "Fortfahren? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo -e "${RED}Abgebrochen.${NC}"
    exit 0
fi

# ==================================================
# SCHRITT 2: Handler-Datei erstellen
# ==================================================
echo ""
echo -e "${YELLOW}Schritt 2: Handler-Datei erstellen${NC}"

HANDLER_FILE="${API_DIR}/src/handlers/${ENDPOINT_NAME}.go"
HANDLER_FUNC_NAME="$(echo ${ENDPOINT_NAME} | sed 's/.*/\u&/')Handler"

if [ -f "$HANDLER_FILE" ]; then
    echo -e "${YELLOW}⚠️  Handler-Datei existiert bereits: ${HANDLER_FILE}${NC}"
    read -p "Überschreiben? (y/n): " OVERWRITE
    if [ "$OVERWRITE" != "y" ]; then
        echo -e "${BLUE}Überspringe Handler-Erstellung${NC}"
    else
        cat > "$HANDLER_FILE" <<EOF
package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// ${HANDLER_FUNC_NAME} handles ${HTTP_METHOD} ${ENDPOINT_PATH}
// Description: ${DESCRIPTION}
func ${HANDLER_FUNC_NAME}(logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// TODO: Implementiere deine Logik hier

		// Beispiel: GET-Request
		if c.Request.Method == "GET" {
			c.JSON(http.StatusOK, gin.H{
				"message": "${DESCRIPTION}",
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
EOF
        echo -e "${GREEN}✅ Handler erstellt: ${HANDLER_FILE}${NC}"
    fi
else
    cat > "$HANDLER_FILE" <<EOF
package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
)

// ${HANDLER_FUNC_NAME} handles ${HTTP_METHOD} ${ENDPOINT_PATH}
// Description: ${DESCRIPTION}
func ${HANDLER_FUNC_NAME}(logger *logrus.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		// TODO: Implementiere deine Logik hier

		// Beispiel: GET-Request
		if c.Request.Method == "GET" {
			c.JSON(http.StatusOK, gin.H{
				"message": "${DESCRIPTION}",
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
EOF
    echo -e "${GREEN}✅ Handler erstellt: ${HANDLER_FILE}${NC}"
fi

# ==================================================
# SCHRITT 3: Route hinzufügen (Anleitung)
# ==================================================
echo ""
echo -e "${YELLOW}Schritt 3: Route in main.go registrieren${NC}"
echo ""
echo -e "${BLUE}Füge folgende Zeile zu ${API_DIR}/src/main.go hinzu:${NC}"
echo ""

if [ "$NEEDS_AUTH" = "y" ]; then
    # Authentifizierte Route
    GROUP_NAME=$(echo "$ENDPOINT_PATH" | sed 's|/api/v1/||' | cut -d'/' -f1)

    echo -e "${GREEN}// In der Nähe von Zeile 247 (nach storageV1 := r.Group(...))${NC}"
    echo -e "${YELLOW}${GROUP_NAME}V1 := r.Group(\"${ENDPOINT_PATH}\")${NC}"
    echo -e "${YELLOW}${GROUP_NAME}V1.Use(${NC}"
    echo -e "${YELLOW}    middleware.AuthMiddleware(jwtService, redis, logger),${NC}"
    echo -e "${YELLOW}    middleware.CSRFMiddleware(redis, logger),${NC}"
    echo -e "${YELLOW})${NC}"
    echo -e "${YELLOW}{${NC}"
    echo -e "${YELLOW}    ${GROUP_NAME}V1.${HTTP_METHOD}(\"\", handlers.${HANDLER_FUNC_NAME}(logger))${NC}"
    echo -e "${YELLOW}}${NC}"
else
    # Öffentliche Route
    echo -e "${GREEN}// In der Nähe von Zeile 228 (im v1 := r.Group(\"/api/v1\") Block)${NC}"
    echo -e "${YELLOW}v1.${HTTP_METHOD}(\"${ENDPOINT_PATH}\", handlers.${HANDLER_FUNC_NAME}(logger))${NC}"
fi

echo ""

# ==================================================
# SCHRITT 4: Test-Eintrag erstellen
# ==================================================
echo -e "${YELLOW}Schritt 4: Test-Eintrag für test-api-endpoints.sh${NC}"
echo ""
echo -e "${BLUE}Füge folgende Zeile zu test-api-endpoints.sh hinzu:${NC}"
echo ""

if [ "$NEEDS_AUTH" = "y" ]; then
    echo -e "${YELLOW}test_endpoint \"${HTTP_METHOD}\" \"${ENDPOINT_PATH}\" \"200\" \"${DESCRIPTION}\" \"true\"${NC}"
else
    echo -e "${YELLOW}test_endpoint \"${HTTP_METHOD}\" \"${ENDPOINT_PATH}\" \"200\" \"${DESCRIPTION}\" \"false\"${NC}"
fi

echo ""

# ==================================================
# SCHRITT 5: Build & Deploy Anweisungen
# ==================================================
echo ""
echo -e "${YELLOW}Schritt 5: Build & Deploy${NC}"
echo ""
echo -e "${BLUE}Führe folgende Befehle aus:${NC}"
echo ""
echo -e "${GREEN}# 1. API neu bauen${NC}"
echo -e "${YELLOW}cd ${API_DIR}${NC}"
echo -e "${YELLOW}docker build --no-cache -t nas-api:1.0.0 .${NC}"
echo ""
echo -e "${GREEN}# 2. Production deployen${NC}"
echo -e "${YELLOW}cd /home/freun/Agent/infrastructure${NC}"
echo -e "${YELLOW}docker compose --env-file .env.prod -f docker-compose.prod.yml up -d api${NC}"
echo ""
echo -e "${GREEN}# 3. Endpoint testen${NC}"
echo -e "${YELLOW}/home/freun/Agent/scripts/test-api-endpoints.sh${NC}"
echo ""

# ==================================================
# ZUSAMMENFASSUNG
# ==================================================
echo -e "${BLUE}=====================================================${NC}"
echo -e "${GREEN}✅ Endpoint-Vorlage erstellt!${NC}"
echo -e "${BLUE}=====================================================${NC}"
echo ""
echo -e "${YELLOW}Nächste Schritte:${NC}"
echo -e "  1. Implementiere die Logik in: ${HANDLER_FILE}"
echo -e "  2. Registriere die Route in: ${API_DIR}/src/main.go"
echo -e "  3. Baue und deploye die API"
echo -e "  4. Teste den Endpoint"
echo ""
echo -e "${BLUE}Viel Erfolg! 🚀${NC}"
echo ""
