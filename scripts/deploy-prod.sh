#!/bin/bash
set -e # Abbruch bei Fehler

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Pfade setzen (Skript kann von überall ausgeführt werden)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFRA_DIR="$BASE_DIR/infrastructure"
ENV_FILE="$INFRA_DIR/.env.prod"
COMPOSE_FILE="$INFRA_DIR/docker-compose.prod.yml"

echo -e "${YELLOW}🚀 NAS.AI Ultimate Deployment & Repair Tool${NC}"
echo "==================================================="

# 1. Check Prerequisites
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}❌ FEHLER: .env.prod nicht gefunden unter $ENV_FILE${NC}"
    exit 1
fi

# Laden der Environment Variablen für das Skript
set -a
source "$ENV_FILE"
set +a

# Domain Check / Fallback
if [ -z "$API_DOMAIN" ]; then
    API_DOMAIN="api.freund-felix.com"
fi
TARGET_API_URL="https://$API_DOMAIN"

# 2. INTERAKTIVE ABFRAGE: Datenbank Reset?
echo -e "${RED}⚠️  ACHTUNG: Datenbank-Status${NC}"
read -p "❓ Soll die Datenbank KOMPLETT gelöscht und neu initialisiert werden? (y/N) " -n 1 -r
echo    # neue Zeile
if [[ $REPLY =~ ^[Yy]$ ]]; then
    DO_RESET=true
    echo -e "${RED}🔥 WARNUNG: Alle Daten werden gelöscht! (Clean Slate)${NC}"
else
    DO_RESET=false
    echo -e "${GREEN}✅ Datenbank bleibt erhalten (Update Mode)${NC}"
fi

echo "==================================================="

# 3. Shutdown & Cleanup
echo -e "${YELLOW}🛑 Stoppe Container...${NC}"
if [ "$DO_RESET" = true ]; then
    # Löscht auch die Volumes (-v)
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" down -v
else
    # Behält Daten
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" down
fi

# 4. Build Frontend (Fix für 502 / Falsche API URL)
echo -e "${YELLOW}🔨 Baue WebUI neu (Ziel: $TARGET_API_URL)...${NC}"
docker build \
  --build-arg VITE_API_BASE_URL="$TARGET_API_URL" \
  -t nas-webui:1.0.0 \
  "$INFRA_DIR/webui"

# 5. Start Container
echo -e "${YELLOW}🚀 Starte System...${NC}"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

# 6. DATENBANK INITIALISIERUNG (Nur bei Reset)
if [ "$DO_RESET" = true ]; then
    echo -e "${YELLOW}⏳ Warte auf Datenbank-Start (15s)...${NC}"
    sleep 15 # Postgres braucht Zeit zum Booten

    echo -e "${YELLOW}💉 Injiziere Datenbank-Schema...${NC}"
    # 1. Init SQL
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T postgres psql -U nas_user -d nas_db < "$INFRA_DIR/db/init.sql"
    
    # 2. Migrations
    echo -e "${YELLOW}💉 Injiziere Migrationen...${NC}"
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T postgres psql -U nas_user -d nas_db < "$INFRA_DIR/db/migrations/001_add_email_verification.sql"
    
    echo -e "${GREEN}✅ Datenbank erfolgreich neu erstellt!${NC}"
fi

# 7. Finaler Neustart & Stabilisierung
# Notwendig, damit API die nun existierende DB findet und Frontend die API
echo -e "${YELLOW}🔄 Finaler Neustart zur Stabilisierung...${NC}"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" restart api webui monitoring analysis-agent pentester-agent

# 8. Health Checks & Validation
echo -e "${YELLOW}🏥 Validiere Container-Status...${NC}"
sleep 5 # Kurze Pause für Container-Start

# Liste der kritischen Container
CRITICAL_CONTAINERS=("postgres" "api" "webui")
OPTIONAL_CONTAINERS=("monitoring" "analysis-agent" "pentester-agent")

# Funktion zum Prüfen eines Container-Status
check_container() {
    local container_name=$1
    local status=$(docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps -q "$container_name" 2>/dev/null)

    if [ -z "$status" ]; then
        return 1 # Container existiert nicht
    fi

    local running=$(docker inspect -f '{{.State.Running}}' $(docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps -q "$container_name") 2>/dev/null)
    if [ "$running" != "true" ]; then
        return 1 # Container läuft nicht
    fi

    return 0 # Container läuft
}

# Prüfe kritische Container
echo -e "${YELLOW}Prüfe kritische Container...${NC}"
FAILED_CONTAINERS=()
for container in "${CRITICAL_CONTAINERS[@]}"; do
    if check_container "$container"; then
        echo -e "${GREEN}✅ $container${NC}"
    else
        echo -e "${RED}❌ $container - FEHLT ODER LÄUFT NICHT!${NC}"
        FAILED_CONTAINERS+=("$container")
    fi
done

# Prüfe optionale Container (nur Warnung, kein Abbruch)
for container in "${OPTIONAL_CONTAINERS[@]}"; do
    if check_container "$container"; then
        echo -e "${GREEN}✅ $container${NC}"
    else
        echo -e "${YELLOW}⚠️  $container - läuft nicht (optional)${NC}"
    fi
done

# Wenn kritische Container fehlen, Fehler ausgeben und abbrechen
if [ ${#FAILED_CONTAINERS[@]} -gt 0 ]; then
    echo -e "${RED}❌ FEHLER: Kritische Container fehlen oder laufen nicht!${NC}"
    echo -e "${RED}   Betroffene Container: ${FAILED_CONTAINERS[*]}${NC}"
    echo -e "${YELLOW}📋 Aktuelle Container-Status:${NC}"
    docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps
    echo -e "${YELLOW}📋 Logs der fehlgeschlagenen Container:${NC}"
    for container in "${FAILED_CONTAINERS[@]}"; do
        echo -e "${YELLOW}--- Logs für $container ---${NC}"
        docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" logs --tail=20 "$container" 2>/dev/null || echo "Keine Logs verfügbar"
    done
    exit 1
fi

# 9. API Health Check (Wenn verfügbar)
echo -e "${YELLOW}🏥 Prüfe API Erreichbarkeit...${NC}"
MAX_RETRIES=12
RETRY_DELAY=5
for i in $(seq 1 $MAX_RETRIES); do
    if docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" exec -T api wget -q --spider http://localhost:8080/api/v1/system/health 2>/dev/null; then
        echo -e "${GREEN}✅ API ist erreichbar!${NC}"
        break
    else
        if [ $i -lt $MAX_RETRIES ]; then
            echo -e "${YELLOW}⏳ API noch nicht bereit... Versuch $i/$MAX_RETRIES (warte ${RETRY_DELAY}s)${NC}"
            sleep $RETRY_DELAY
        else
            echo -e "${YELLOW}⚠️  API antwortet nicht auf Health Check (Timeout nach 60s)${NC}"
            echo -e "${YELLOW}   Dies könnte normal sein, wenn die API noch startet.${NC}"
            echo -e "${YELLOW}   Prüfe die Logs mit: docker compose -f $COMPOSE_FILE logs api${NC}"
        fi
    fi
done

echo "==================================================="
echo -e "${GREEN}✅ DEPLOYMENT ABGESCHLOSSEN${NC}"
echo -e "Frontend: https://${FRONTEND_URL:-freund-felix.com}"
echo -e "API:      $TARGET_API_URL"
echo -e "${YELLOW}👉 Falls du 'Reset' gewählt hast: Erstelle jetzt einen neuen Admin-Account!${NC}"
echo ""
echo -e "${YELLOW}📊 Container-Übersicht:${NC}"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps
