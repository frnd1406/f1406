#!/bin/bash

# Farben für schöne Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

set -euo pipefail

echo -e "${BLUE}=== 🤖 NAS AI SYSTEM INTEGRATION TEST ===${NC}"

# 1. Aufräumen
echo -e "${YELLOW}[1/4] Bereinige Datenbank (Tabula Rasa)...${NC}"
docker exec nas-api-postgres psql -U nas_user -d nas_db -c "TRUNCATE TABLE system_alerts;" > /dev/null
echo -e "${GREEN}✔ Datenbank geleert.${NC}"

# 2. Neustart
echo -e "${YELLOW}[2/4] Starte Analysis Agent neu (Cache Reset)...${NC}"
docker restart nas-analysis-agent > /dev/null
# Wir warten kurz, damit der Container oben ist
sleep 3
echo -e "${GREEN}✔ Agent läuft.${NC}"

# 3. Angriff simulieren
TIMESTAMP=$(date +%s)
echo -e "${YELLOW}[3/4] Sende CRITICAL Alert (Timestamp: ${TIMESTAMP})...${NC}"
curl -s -X POST http://localhost:8080/api/v1/system/alerts \
  -H "Content-Type: application/json" \
  -d "{\"severity\": \"CRITICAL\", \"message\": \"Filesystem /dev/sda1 is mounted Read-Only. Write operations failed at ${TIMESTAMP}.\"}" > /dev/null
echo -e "${GREEN}✔ Alert gesendet.${NC}"

# 4. Warten auf Intelligenz (Der Gedulds-Teil)
echo -e "${BLUE}[4/4] Warte auf KI-Antwort (Phi-3 auf Raspberry Pi)...${NC}"
echo -e "    Dies kann bis zu 90 Sekunden dauern. Bitte warten..."

START_TIME=$SECONDS
TIMEOUT=120

while true; do
    # Wir fragen direkt die Datenbank, ob in der Spalte 'ai_analysis' etwas steht
    RESULT=$(docker exec nas-api-postgres psql -U nas_user -d nas_db -t -c "SELECT ai_analysis FROM system_alerts WHERE severity='CRITICAL' AND ai_analysis IS NOT NULL ORDER BY created_at DESC LIMIT 1;" | xargs)

    if [ ! -z "$RESULT" ]; then
        ELAPSED=$(($SECONDS - $START_TIME))
        echo ""
        echo -e "${GREEN}✅ ERFOLG! Die KI hat nach ${ELAPSED} Sekunden geantwortet!${NC}"
        echo ""
        echo -e "${YELLOW}--- KI EMPFEHLUNG ---${NC}"
        echo -e "${RESULT}"
        echo -e "${YELLOW}---------------------${NC}"
        exit 0
    fi

    # Timeout Check
    if [ $(($SECONDS - $START_TIME)) -ge $TIMEOUT ]; then
        echo ""
        echo -e "${RED}❌ TIMEOUT! Keine Antwort nach ${TIMEOUT} Sekunden.${NC}"
        echo "Prüfe Logs mit: docker logs nas-analysis-agent"
        exit 1
    fi

    # Spinner / Warte-Animation
    printf "."
    sleep 2
done