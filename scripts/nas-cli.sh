#!/bin/bash
set -euo pipefail

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Konfiguration
API_URL="${API_URL:-https://felix-freund.com}"
INFRA_DIR="/home/freun/Agent/infrastructure"
SCRIPTS_DIR="/home/freun/Agent/scripts"

# Global variables for monitoring
CONSECUTIVE_FAILURES=0
TOTAL_CHECKS=0
TOTAL_FAILURES=0
START_TIME=$(date +%s)

# ============================================================================
# HEADER
# ============================================================================
show_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                                    ║${NC}"
    echo -e "${BLUE}║                ${CYAN}NAS.AI Infrastructure Management CLI${BLUE}                ║${NC}"
    echo -e "${BLUE}║                                                                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}  API URL:${NC} $API_URL"
    echo -e "${CYAN}  Infrastructure:${NC} $INFRA_DIR"
    echo ""
}

# ============================================================================
# MAIN MENU
# ============================================================================
main_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}┌─ Hauptmenü ────────────────────────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}1)${NC} 🔍 API Testing & Monitoring                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}2)${NC} 🚀 Deployment & Container Management                           ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}3)${NC} 📊 System Information & Logs                                   ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}4)${NC} 🛠️  Development Tools                                          ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}5)${NC} 📚 Documentation                                               ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${RED}0)${NC} ❌ Exit                                                        ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}└────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        read -p "$(echo -e ${CYAN}Wähle eine Option: ${NC})" choice

        case $choice in
            1) api_testing_menu ;;
            2) deployment_menu ;;
            3) system_info_menu ;;
            4) dev_tools_menu ;;
            5) documentation_menu ;;
            0) exit 0 ;;
            *) echo -e "${RED}Ungültige Option!${NC}"; sleep 2 ;;
        esac
    done
}

# ============================================================================
# API TESTING & MONITORING MENU
# ============================================================================
api_testing_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}┌─ API Testing & Monitoring ─────────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}1)${NC} 🧪 Quick API Health Check                                      ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}2)${NC} 🔄 Continuous Health Monitoring                                ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}2)${NC} 🔄 Continuous Health Monitoring                                ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}6)${NC} 🎯 Custom Endpoint Test                                        ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}4)${NC} 🔐 Test Protected Endpoints (with Auth)                        ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}3)${NC} 📋 Test All Endpoints (Public)                                 ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}5)${NC} 📈 Performance Test (Load Test)                                ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${RED}0)${NC} ⬅️  Zurück                                                     ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}└────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        read -p "$(echo -e ${CYAN}Wähle eine Option: ${NC})" choice

        case $choice in
            1) quick_health_check ;;
            2) continuous_monitoring ;;
            3) test_all_endpoints ;;
            4) test_protected_endpoints ;;
            5) performance_test ;;
            6) custom_endpoint_test ;;
            0) return ;;
            *) echo -e "${RED}Ungültige Option!${NC}"; sleep 2 ;;
        esac
    done
}

# ============================================================================
# DEPLOYMENT MENU
# ============================================================================
deployment_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}┌─ Deployment & Container Management ────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}1)${NC} 🚀 Full Production Deploy (mit DB Reset)                        ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}2)${NC} 🔄 Quick Restart (ohne DB Reset)                                ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}3)${NC} 🏗️  Rebuild einzelner Service                                  ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}4)${NC} 📦 Container Status anzeigen                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}5)${NC} 🛑 Services stoppen                                             ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}6)${NC} ▶️  Services starten                                           ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}7)${NC} 🗑️  Volumes löschen (Clean State)                              ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${RED}0)${NC} ⬅️  Zurück                                                     ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}└────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        read -p "$(echo -e ${CYAN}Wähle eine Option: ${NC})" choice

        case $choice in
            1) full_deploy ;;
            2) quick_restart ;;
            3) rebuild_service ;;
            4) show_container_status ;;
            5) stop_services ;;
            6) start_services ;;
            7) clean_volumes ;;
            0) return ;;
            *) echo -e "${RED}Ungültige Option!${NC}"; sleep 2 ;;
        esac
    done
}

# ============================================================================
# SYSTEM INFO MENU
# ============================================================================
system_info_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}┌─ System Information & Logs ────────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}1)${NC} 📊 Container Status & Resources                                 ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}2)${NC} 📝 Live Logs (alle Services)                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}3)${NC} 🔍 Logs einzelner Service                                       ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}4)${NC} 🐛 Error Logs durchsuchen                                       ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}5)${NC} 💾 Disk Usage                                                   ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}6)${NC} 🌐 Network Info                                                 ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${RED}0)${NC} ⬅️  Zurück                                                     ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}└────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        read -p "$(echo -e ${CYAN}Wähle eine Option: ${NC})" choice

        case $choice in
            1) container_resources ;;
            2) live_logs_all ;;
            3) logs_single_service ;;
            4) search_errors ;;
            5) disk_usage ;;
            6) network_info ;;
            0) return ;;
            *) echo -e "${RED}Ungültige Option!${NC}"; sleep 2 ;;
        esac
    done
}

# ============================================================================
# DEV TOOLS MENU
# ============================================================================
dev_tools_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}┌─ Development Tools ────────────────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}1)${NC} ➕ Neuen API Endpoint erstellen                                 ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}2)${NC} 📚 API Dokumentation generieren                                 ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}3)${NC} 🔧 Database Shell (psql)                                        ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}4)${NC} 🐳 API Container Shell                                          ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}5)${NC} 📦 Backup erstellen                                             ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}6)${NC} ♻️  Backup wiederherstellen                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${RED}0)${NC} ⬅️  Zurück                                                     ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}└────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        read -p "$(echo -e ${CYAN}Wähle eine Option: ${NC})" choice

        case $choice in
            1) "${SCRIPTS_DIR}/add-api-endpoint.sh"; read -p "Drücke Enter..." ;;
            2) "${SCRIPTS_DIR}/generate-api-docs.sh"; read -p "Drücke Enter..." ;;
            3) db_shell ;;
            4) api_shell ;;
            5) create_backup ;;
            6) restore_backup ;;
            0) return ;;
            *) echo -e "${RED}Ungültige Option!${NC}"; sleep 2 ;;
        esac
    done
}

# ============================================================================
# DOCUMENTATION MENU
# ============================================================================
documentation_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}┌─ Documentation ────────────────────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}1)${NC} 📖 API Endpoints Dokumentation                                  ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}2)${NC} 📋 Quick Reference                                              ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${GREEN}3)${NC} 📝 Scripts README                                               ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}  ${RED}0)${NC} ⬅️  Zurück                                                     ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}└────────────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        read -p "$(echo -e ${CYAN}Wähle eine Option: ${NC})" choice

        case $choice in
            1) less /home/freun/Agent/API_ENDPOINTS.md ;;
            2) cat "${SCRIPTS_DIR}/API_QUICK_REFERENCE.txt"; read -p "Drücke Enter..." ;;
            3) less "${SCRIPTS_DIR}/README.md" ;;
            0) return ;;
            *) echo -e "${RED}Ungültige Option!${NC}"; sleep 2 ;;
        esac
    done
}

# ============================================================================
# API TESTING FUNCTIONS
# ============================================================================

# Quick Health Check
quick_health_check() {
    show_header
    echo -e "${CYAN}🔍 Quick Health Check...${NC}"
    echo ""

    declare -A endpoints=(
        ["/health"]="200"
        ["/api/v1/system/metrics?limit=1"]="200"
        ["/api/v1/system/alerts"]="200"
    )

    for endpoint in "${!endpoints[@]}"; do
        expected=${endpoints[$endpoint]}
        response=$(curl -s -w '\n%{http_code}\n%{time_total}' -m 5 "${API_URL}${endpoint}" 2>/dev/null || echo -e "\nERROR\n0")
        status_code=$(echo "$response" | tail -n 2 | head -n 1)
        response_time=$(echo "$response" | tail -n 1)

        if [ "$status_code" = "$expected" ]; then
            response_ms=$(echo "$response_time * 1000" | bc)
            printf "${GREEN}✓${NC} %-45s OK (%.0fms)\n" "$endpoint" "$response_ms"
        else
            printf "${RED}✗${NC} %-45s FAILED (Status: %s)\n" "$endpoint" "$status_code"
        fi
    done

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Continuous Monitoring
continuous_monitoring() {
    show_header
    echo -e "${CYAN}🔄 Starte kontinuierliches Monitoring...${NC}"
    echo -e "${YELLOW}(Drücke Ctrl+C zum Beenden)${NC}"
    echo ""

    TOTAL_CHECKS=0
    TOTAL_FAILURES=0
    CONSECUTIVE_FAILURES=0
    START_TIME=$(date +%s)

    while true; do
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        timestamp=$(date '+%H:%M:%S')

        response=$(curl -s -w '\n%{http_code}\n%{time_total}' -m 5 "${API_URL}/health" 2>/dev/null || echo -e "\nERROR\n0")
        status_code=$(echo "$response" | tail -n 2 | head -n 1)
        response_time=$(echo "$response" | tail -n 1)

        if [ "$status_code" = "200" ]; then
            CONSECUTIVE_FAILURES=0
            response_ms=$(echo "$response_time * 1000" | bc)

            if (( $(echo "$response_time < 0.5" | bc -l) )); then
                color=$GREEN; status="EXCELLENT"
            elif (( $(echo "$response_time < 1.0" | bc -l) )); then
                color=$CYAN; status="GOOD"
            else
                color=$YELLOW; status="SLOW"
            fi

            printf "${color}✓${NC} [%s] %s (%.0fms)\n" "$timestamp" "$status" "$response_ms"
        else
            CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))
            TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
            printf "${RED}✗${NC} [%s] FAILED (%d/%d failures)\n" "$timestamp" "$CONSECUTIVE_FAILURES" 3
        fi

        if [ $((TOTAL_CHECKS % 10)) -eq 0 ]; then
            uptime=$(($(date +%s) - START_TIME))
            success_rate=$(echo "scale=1; (($TOTAL_CHECKS - $TOTAL_FAILURES) / $TOTAL_CHECKS) * 100" | bc)
            echo -e "${BLUE}📊 Checks: $TOTAL_CHECKS | Failures: $TOTAL_FAILURES | Success: ${success_rate}%${NC}"
        fi

        sleep 5
    done
}

# Test All Endpoints
test_all_endpoints() {
    show_header
    echo -e "${CYAN}📋 Teste alle öffentlichen Endpoints...${NC}"
    echo ""

    endpoints=(
        "GET:/health:200"
        "GET:/api/v1/system/metrics?limit=1:200"
        "GET:/api/v1/system/alerts:200"
        "GET:/api/v1/auth/csrf:200"
    )

    for endpoint_def in "${endpoints[@]}"; do
        IFS=':' read -r method path expected <<< "$endpoint_def"

        response=$(curl -s -w '\n%{http_code}' -X "$method" -m 5 "${API_URL}${path}" 2>/dev/null || echo -e "\nERROR")
        status_code=$(echo "$response" | tail -n 1)

        if [ "$status_code" = "$expected" ]; then
            printf "${GREEN}✓${NC} %-10s %-50s ${GREEN}%s${NC}\n" "$method" "$path" "$status_code"
        else
            printf "${RED}✗${NC} %-10s %-50s ${RED}%s${NC} (expected: %s)\n" "$method" "$path" "$status_code" "$expected"
        fi
    done

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Test Protected Endpoints
test_protected_endpoints() {
    show_header
    echo -e "${CYAN}🔐 Teste geschützte Endpoints...${NC}"
    echo ""

    if [ -z "${JWT_TOKEN:-}" ]; then
        echo -e "${YELLOW}⚠️  Keine JWT_TOKEN Variable gesetzt!${NC}"
        echo ""
        echo "Um geschützte Endpoints zu testen:"
        echo "1. Melde dich in der WebUI an"
        echo "2. Öffne Browser DevTools (F12)"
        echo "3. Gehe zu Application/Storage > Cookies"
        echo "4. Kopiere den JWT Token"
        echo "5. Starte das Script mit: JWT_TOKEN='your-token' CSRF_TOKEN='csrf' ./nas-cli.sh"
        echo ""
        read -p "Drücke Enter um fortzufahren..."
        return
    fi

    endpoints=(
        "GET:/api/v1/system/settings:200"
        "GET:/api/v1/backups:200"
        "GET:/api/v1/storage/files?path=/:200"
        "GET:/api/v1/storage/trash:200"
    )

    for endpoint_def in "${endpoints[@]}"; do
        IFS=':' read -r method path expected <<< "$endpoint_def"

        response=$(curl -s -w '\n%{http_code}' \
            -X "$method" \
            -H "Authorization: Bearer ${JWT_TOKEN}" \
            -H "X-CSRF-Token: ${CSRF_TOKEN:-}" \
            -m 5 "${API_URL}${path}" 2>/dev/null || echo -e "\nERROR")
        status_code=$(echo "$response" | tail -n 1)

        if [ "$status_code" = "$expected" ]; then
            printf "${GREEN}✓${NC} %-10s %-50s ${GREEN}%s${NC}\n" "$method" "$path" "$status_code"
        else
            printf "${RED}✗${NC} %-10s %-50s ${RED}%s${NC} (expected: %s)\n" "$method" "$path" "$status_code" "$expected"
        fi
    done

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Performance Test
performance_test() {
    show_header
    echo -e "${CYAN}📈 Performance Test (Load Test)...${NC}"
    echo ""
    read -p "Anzahl der Requests: " num_requests
    read -p "Concurrency Level: " concurrency

    echo ""
    echo -e "${YELLOW}Starte Load Test mit $num_requests Requests ($concurrency concurrent)...${NC}"
    echo ""

    ab -n "$num_requests" -c "$concurrency" "${API_URL}/health" 2>/dev/null || {
        echo -e "${RED}Apache Bench (ab) nicht installiert!${NC}"
        echo "Install mit: sudo apt-get install apache2-utils"
    }

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Custom Endpoint Test
custom_endpoint_test() {
    show_header
    echo -e "${CYAN}🎯 Custom Endpoint Test${NC}"
    echo ""

    read -p "Methode (GET/POST/PUT/DELETE): " method
    read -p "Endpoint Path (z.B. /api/v1/test): " path
    read -p "Expected Status Code (z.B. 200): " expected

    echo ""
    echo -e "${YELLOW}Sende Request...${NC}"

    response=$(curl -s -w '\n%{http_code}\n%{time_total}' \
        -X "$method" \
        -m 10 "${API_URL}${path}" 2>/dev/null || echo -e "\nERROR\n0")

    status_code=$(echo "$response" | tail -n 2 | head -n 1)
    response_time=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -2)

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Response:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ "$status_code" = "$expected" ]; then
        echo -e "${GREEN}Status: $status_code ✓${NC}"
    else
        echo -e "${RED}Status: $status_code ✗ (expected: $expected)${NC}"
    fi

    response_ms=$(echo "$response_time * 1000" | bc)
    echo -e "Time: $(printf '%.0f' $response_ms)ms"
    echo ""
    echo -e "${CYAN}Body:${NC}"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# ============================================================================
# DEPLOYMENT FUNCTIONS
# ============================================================================

# Full Deploy
full_deploy() {
    show_header
    echo -e "${RED}⚠️  WARNUNG: Vollständiger Deploy mit Datenbank-Reset!${NC}"
    echo -e "${RED}Alle Daten werden gelöscht!${NC}"
    echo ""
    read -p "Fortfahren? (y/N): " confirm

    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi

    echo ""
    echo -e "${YELLOW}🛑 Stoppe Container und lösche Volumes...${NC}"
    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml down -v

    echo -e "${YELLOW}🚀 Starte Container...${NC}"
    docker compose --env-file .env.prod -f docker-compose.prod.yml up -d

    echo -e "${YELLOW}⏳ Warte auf Datenbank (15s)...${NC}"
    sleep 15

    echo -e "${YELLOW}💉 Initialisiere Datenbank...${NC}"
    docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T postgres \
        psql -U nas_user -d nas_db < db/init.sql

    docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T postgres \
        psql -U nas_user -d nas_db < db/migrations/001_add_email_verification.sql

    echo -e "${YELLOW}🔧 Fixe Permissions...${NC}"
    sudo chmod 777 /var/lib/docker/volumes/infrastructure_nas_backups/_data
    sudo chmod 777 /var/lib/docker/volumes/infrastructure_nas_data/_data

    echo ""
    echo -e "${GREEN}✅ Deploy abgeschlossen!${NC}"
    docker compose --env-file .env.prod -f docker-compose.prod.yml ps

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Quick Restart
quick_restart() {
    show_header
    echo -e "${YELLOW}🔄 Quick Restart (ohne DB Reset)...${NC}"
    echo ""

    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml restart

    echo ""
    echo -e "${GREEN}✅ Restart abgeschlossen!${NC}"
    docker compose --env-file .env.prod -f docker-compose.prod.yml ps

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Rebuild Service
rebuild_service() {
    show_header
    echo -e "${CYAN}🏗️  Service auswählen zum Rebuilden:${NC}"
    echo ""
    echo "1) API"
    echo "2) WebUI"
    echo "3) Monitoring"
    echo "4) Analysis Agent"
    echo "5) Pentester Agent"
    echo "0) Abbrechen"
    echo ""
    read -p "Wähle Service: " service_choice

    case $service_choice in
        1) service="api" ;;
        2) service="webui" ;;
        3) service="monitoring" ;;
        4) service="analysis-agent" ;;
        5) service="pentester-agent" ;;
        0) return ;;
        *) echo -e "${RED}Ungültig!${NC}"; sleep 2; return ;;
    esac

    echo ""
    echo -e "${YELLOW}Rebuilde $service...${NC}"
    cd "$INFRA_DIR"

    if [ "$service" = "api" ]; then
        cd api
        docker build --no-cache -t nas-api:1.0.0 .
    elif [ "$service" = "webui" ]; then
        docker build --no-cache --build-arg VITE_API_BASE_URL="https://felix-freund.com" -t nas-webui:1.0.0 webui
    fi

    echo -e "${YELLOW}Starte Service neu...${NC}"
    docker compose --env-file .env.prod -f docker-compose.prod.yml up -d "$service"

    echo ""
    echo -e "${GREEN}✅ Service $service erfolgreich rebuilt!${NC}"
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Show Container Status
show_container_status() {
    show_header
    echo -e "${CYAN}📦 Container Status:${NC}"
    echo ""

    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml ps

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Stop Services
stop_services() {
    show_header
    echo -e "${YELLOW}🛑 Stoppe alle Services...${NC}"
    echo ""

    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml down

    echo ""
    echo -e "${GREEN}✅ Alle Services gestoppt!${NC}"
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Start Services
start_services() {
    show_header
    echo -e "${YELLOW}▶️  Starte alle Services...${NC}"
    echo ""

    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml up -d

    echo ""
    echo -e "${GREEN}✅ Services gestartet!${NC}"
    docker compose --env-file .env.prod -f docker-compose.prod.yml ps

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Clean Volumes
clean_volumes() {
    show_header
    echo -e "${RED}⚠️  WARNUNG: Clean State - Alle Volumes werden gelöscht!${NC}"
    echo ""
    read -p "Wirklich fortfahren? (y/N): " confirm

    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        return
    fi

    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml down -v

    echo ""
    echo -e "${GREEN}✅ Volumes gelöscht!${NC}"
    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# ============================================================================
# SYSTEM INFO FUNCTIONS
# ============================================================================

# Container Resources
container_resources() {
    show_header
    echo -e "${CYAN}📊 Container Resources:${NC}"
    echo ""

    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Live Logs All
live_logs_all() {
    show_header
    echo -e "${CYAN}📝 Live Logs (Ctrl+C zum Beenden)${NC}"
    echo ""

    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f
}

# Logs Single Service
logs_single_service() {
    show_header
    echo -e "${CYAN}🔍 Logs für einzelnen Service:${NC}"
    echo ""
    echo "1) API"
    echo "2) WebUI"
    echo "3) Postgres"
    echo "4) Redis"
    echo "5) Monitoring"
    echo "6) Analysis Agent"
    echo "7) Pentester Agent"
    echo "0) Abbrechen"
    echo ""
    read -p "Wähle Service: " service_choice

    case $service_choice in
        1) service="api" ;;
        2) service="webui" ;;
        3) service="postgres" ;;
        4) service="redis" ;;
        5) service="monitoring" ;;
        6) service="analysis-agent" ;;
        7) service="pentester-agent" ;;
        0) return ;;
        *) echo -e "${RED}Ungültig!${NC}"; sleep 2; return ;;
    esac

    echo ""
    read -p "Anzahl der Zeilen (z.B. 50): " lines

    echo ""
    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml logs --tail="$lines" "$service"

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Search Errors
search_errors() {
    show_header
    echo -e "${CYAN}🐛 Suche nach Fehlern in Logs...${NC}"
    echo ""

    cd "$INFRA_DIR"
    echo -e "${YELLOW}Fehler in API Logs:${NC}"
    docker compose --env-file .env.prod -f docker-compose.prod.yml logs api | grep -i "error\|fatal\|panic" | tail -20

    echo ""
    echo -e "${YELLOW}Fehler in WebUI Logs:${NC}"
    docker compose --env-file .env.prod -f docker-compose.prod.yml logs webui | grep -i "error\|emerg" | tail -20

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Disk Usage
disk_usage() {
    show_header
    echo -e "${CYAN}💾 Disk Usage:${NC}"
    echo ""

    echo -e "${YELLOW}Docker Volumes:${NC}"
    docker system df -v | grep infrastructure

    echo ""
    echo -e "${YELLOW}System Disk:${NC}"
    df -h /var/lib/docker

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Network Info
network_info() {
    show_header
    echo -e "${CYAN}🌐 Network Info:${NC}"
    echo ""

    docker network ls | grep infrastructure

    echo ""
    echo -e "${YELLOW}NAS Network:${NC}"
    docker network inspect infrastructure_nas-network | jq '.[0].Containers'

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# ============================================================================
# DEV TOOLS FUNCTIONS
# ============================================================================

# DB Shell
db_shell() {
    show_header
    echo -e "${CYAN}🔧 Database Shell (psql)${NC}"
    echo -e "${YELLOW}Beende mit \\q${NC}"
    echo ""

    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml exec postgres psql -U nas_user -d nas_db
}

# API Shell
api_shell() {
    show_header
    echo -e "${CYAN}🐳 API Container Shell${NC}"
    echo -e "${YELLOW}Beende mit exit${NC}"
    echo ""

    cd "$INFRA_DIR"
    docker compose --env-file .env.prod -f docker-compose.prod.yml exec api sh
}

# Create Backup
create_backup() {
    show_header
    echo -e "${CYAN}📦 Backup erstellen...${NC}"
    echo ""

    if [ -z "${JWT_TOKEN:-}" ]; then
        echo -e "${RED}JWT_TOKEN nicht gesetzt!${NC}"
        echo "Bitte zuerst einloggen und Token setzen."
        echo ""
        read -p "Drücke Enter um fortzufahren..."
        return
    fi

    echo -e "${YELLOW}Erstelle Backup via API...${NC}"

    response=$(curl -s -w '\n%{http_code}' \
        -X POST \
        -H "Authorization: Bearer ${JWT_TOKEN}" \
        -H "X-CSRF-Token: ${CSRF_TOKEN:-}" \
        "${API_URL}/api/v1/backups")

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -1)

    if [ "$status_code" = "201" ] || [ "$status_code" = "200" ]; then
        echo -e "${GREEN}✅ Backup erfolgreich erstellt!${NC}"
        echo "$body" | jq '.'
    else
        echo -e "${RED}✗ Backup fehlgeschlagen! Status: $status_code${NC}"
        echo "$body"
    fi

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# Restore Backup
restore_backup() {
    show_header
    echo -e "${CYAN}♻️  Backup wiederherstellen${NC}"
    echo ""

    if [ -z "${JWT_TOKEN:-}" ]; then
        echo -e "${RED}JWT_TOKEN nicht gesetzt!${NC}"
        echo ""
        read -p "Drücke Enter um fortzufahren..."
        return
    fi

    echo -e "${YELLOW}Verfügbare Backups:${NC}"
    backups=$(curl -s \
        -H "Authorization: Bearer ${JWT_TOKEN}" \
        "${API_URL}/api/v1/backups" | jq -r '.items[].id')

    echo "$backups"
    echo ""
    read -p "Backup ID zum Wiederherstellen: " backup_id

    echo ""
    echo -e "${YELLOW}Stelle Backup wieder her...${NC}"

    response=$(curl -s -w '\n%{http_code}' \
        -X POST \
        -H "Authorization: Bearer ${JWT_TOKEN}" \
        -H "X-CSRF-Token: ${CSRF_TOKEN:-}" \
        "${API_URL}/api/v1/backups/${backup_id}/restore")

    status_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -1)

    if [ "$status_code" = "200" ]; then
        echo -e "${GREEN}✅ Backup erfolgreich wiederhergestellt!${NC}"
    else
        echo -e "${RED}✗ Fehler! Status: $status_code${NC}"
        echo "$body"
    fi

    echo ""
    read -p "Drücke Enter um fortzufahren..."
}

# ============================================================================
# MAIN
# ============================================================================
main_menu
