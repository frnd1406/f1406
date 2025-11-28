#!/bin/bash
set -euo pipefail

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_DIR="$ROOT_DIR/infrastructure"
API_DIR="$INFRA_DIR/api"
DOC_OUTPUT="$ROOT_DIR/API_ENDPOINTS.md"
COMPOSE_FILE="$INFRA_DIR/docker-compose.prod.yml"
ENV_FILE="$INFRA_DIR/.env.prod"
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$INFRA_DIR")}"
DC_CMD="docker compose -f \"$COMPOSE_FILE\""

API_URL_DEFAULT="https://felix-freund.com"
API_URL="${API_URL:-$API_URL_DEFAULT}"
VERBOSE="${VERBOSE:-false}"
CURL_AUTH_HEADERS=()

print_header() {
  clear
  printf "%s\n" \
    "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}" \
    "${BLUE}║${NC}   🚀 ${CYAN}NAS.AI Infrastructure CLI (Monolith)${NC}                      ${BLUE}║${NC}" \
    "${BLUE}║${NC}   ${YELLOW}Stabilität · Sicherheit · DX${NC}                              ${BLUE}║${NC}" \
    "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}" \
    ""
  printf "%s\n" "${CYAN}Root:${NC} ${ROOT_DIR}"
  printf "%s\n" "${CYAN}API URL:${NC} ${API_URL}"
  printf "%s\n" ""
}

fail() { echo -e "${RED}❌ $*${NC}" >&2; exit 1; }
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
ok()   { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }

require_cmd() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Befehl fehlt: $cmd"
  done
}

check_prereqs() {
  require_cmd docker curl jq git
  [ -f "$COMPOSE_FILE" ] || warn "Hinweis: $COMPOSE_FILE fehlt (Compose-Befehle könnten fehlschlagen)."
}

# --- Utility: curl wrapper ----------------------------------------------------
http_request() {
  local method=$1 path=$2 expected=$3 timeout=${4:-8} data=${5:-}
  local url="${API_URL}${path}"
  local tmp_body
  tmp_body=$(mktemp)
  local code

  if [ -n "$data" ]; then
    code=$(curl -sS -o "$tmp_body" -w '%{http_code}' -X "$method" \
      -H "Content-Type: application/json" \
      "${CURL_AUTH_HEADERS[@]}" \
      --data "$data" \
      --max-time "$timeout" \
      "$url" || echo "000")
  else
    code=$(curl -sS -o "$tmp_body" -w '%{http_code}' -X "$method" \
      "${CURL_AUTH_HEADERS[@]}" \
      --max-time "$timeout" \
      "$url" || echo "000")
  fi

  local body
  body=$(cat "$tmp_body")
  rm -f "$tmp_body"

  local parsed
  parsed=$(echo "$body" | jq -c '.' 2>/dev/null || echo "$body")

  if [ "$code" = "$expected" ]; then
    ok "$method $path ($code)"
    [ -n "$parsed" ] && [ "$VERBOSE" = "true" ] && echo "$parsed"
    return 0
  else
    echo -e "${RED}❌ $method $path - erwartet $expected, erhalten $code${NC}"
    [ -n "$parsed" ] && echo -e "${YELLOW}Antwort:${NC} $parsed"
    return 1
  fi
}

# --- API Health --------------------------------------------------------------
health_single() {
  info "Starte Einzel-Health-Check gegen ${API_URL}"
  local endpoints=(
    "GET /health 200"
    "GET /api/v1/system/metrics?limit=1 200"
    "GET /api/v1/system/alerts 200"
  )
  local failures=0
  for line in "${endpoints[@]}"; do
    IFS=' ' read -r method path expected <<<"$line"
    http_request "$method" "$path" "$expected" || failures=$((failures+1))
  done
  [ "$failures" -eq 0 ] || fail "$failures Checks fehlgeschlagen"
}

health_monitor() {
  local interval="${CHECK_INTERVAL:-15}"
  info "Monitoring gestartet (Intervall ${interval}s, API ${API_URL}). Strg+C zum Beenden."
  while true; do
    local ts
    ts="$(date '+%H:%M:%S')"
    if http_request GET /health 200 6 >/dev/null; then
      echo -e "${GREEN}[$ts] OK${NC}"
    else
      echo -e "${RED}[$ts] FEHLER${NC}"
    fi
    sleep "$interval"
  done
}

# --- Endpoint Tests ----------------------------------------------------------
test_endpoints() {
  VERBOSE="${VERBOSE:-false}"
  info "Starte Endpoint-Tests (API ${API_URL})"

  local tests=(
    "GET /health 200 Public-Health"
    "GET /api/v1/system/metrics?limit=1 200 Public-Metrics"
    "GET /api/v1/system/alerts 200 Public-Alerts"
    "POST /auth/login 400 Invalid-Login"
    "GET /api/v1/auth/csrf 200 CSRF-Token"
    "GET /api/v1/system/settings 401 Settings-NoAuth"
    "GET /api/v1/backups 401 Backups-NoAuth"
    "GET /api/v1/storage/files?path=/ 401 Storage-NoAuth"
  )

  CURL_AUTH_HEADERS=()
  if [ -n "${JWT_TOKEN:-}" ] && [ -n "${CSRF_TOKEN:-}" ]; then
    CURL_AUTH_HEADERS=(-H "Authorization: Bearer ${JWT_TOKEN}" -H "X-CSRF-Token: ${CSRF_TOKEN}")
    tests+=(
      "GET /api/v1/system/settings 200 Settings"
      "GET /api/v1/backups 200 Backups"
      "GET /api/v1/storage/files?path=/ 200 Storage"
    )
  else
    warn "JWT_TOKEN/CSRF_TOKEN nicht gesetzt – Auth-Tests werden übersprungen."
  fi

  local failures=0
  for t in "${tests[@]}"; do
    IFS=' ' read -r method path expected label <<<"$t"
    echo -e "${BLUE}➜${NC} $label"
    http_request "$method" "$path" "$expected" 8 || failures=$((failures+1))
  done

  [ "$failures" -eq 0 ] && ok "Alle Tests bestanden" || fail "$failures Tests fehlgeschlagen"
}

# --- Git Savepoint -----------------------------------------------------------
git_savepoint() {
  info "Git Savepoint (Repo: $ROOT_DIR)"
  if [ ! -d "$ROOT_DIR/.git" ]; then
    git -C "$ROOT_DIR" init
    ok "Git init ausgeführt."
  fi

  local status
  status="$(git -C "$ROOT_DIR" status --porcelain)"
  if [ -z "$status" ]; then
    ok "Keine Änderungen – nichts zu tun."
    return 0
  fi

  git -C "$ROOT_DIR" add -A

  read -r -p "Commit-Message: " msg
  if [ -z "$msg" ]; then
    msg="Auto-savepoint $(date '+%Y-%m-%d %H:%M:%S')"
    warn "Leere Message, verwende: $msg"
  fi

  git -C "$ROOT_DIR" commit -m "$msg"

  if git -C "$ROOT_DIR" remote get-url origin >/dev/null 2>&1; then
    local branch
    branch="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD)"
    git -C "$ROOT_DIR" pull --rebase origin "$branch" || warn "Pull fehlgeschlagen, setze fort."
    git -C "$ROOT_DIR" push -u origin "$branch"
    ok "Commit gepusht."
  else
    warn "Kein Remote konfiguriert – Commit nur lokal."
  fi
}

# --- API Docs ----------------------------------------------------------------
generate_api_docs() {
  info "Generiere API Docs nach $DOC_OUTPUT"
  cat > "$DOC_OUTPUT" <<EOF
# NAS.AI API Dokumentation

Automatisch generiert am: $(date)

**Base URL:** \`${API_URL}\`

## Public Endpoints
- GET /health
- GET /api/v1/system/metrics
- GET /api/v1/system/alerts

## Auth Endpoints
- POST /auth/login
- POST /auth/register
- POST /auth/refresh
- POST /auth/logout

## Geschützte Endpoints (JWT + CSRF)
- GET /api/v1/system/settings
- PUT /api/v1/system/settings/backup
- POST /api/v1/system/validate-path
- GET /api/v1/backups
- POST /api/v1/backups
- POST /api/v1/backups/{id}/restore
- DELETE /api/v1/backups/{id}
- GET /api/v1/storage/files
- POST /api/v1/storage/upload
- DELETE /api/v1/storage/delete
- GET /api/v1/storage/trash
- POST /api/v1/storage/trash/restore/{id}
- DELETE /api/v1/storage/trash/{id}
- POST /api/v1/storage/rename

Hinweis: Weitere Details siehe Swagger (nur in DEV verfügbar) oder Backend-Code unter $API_DIR/src.
EOF
  ok "Dokumentation erstellt."
}

# --- Logs --------------------------------------------------------------------
tail_logs() {
  if [ ! -f "$COMPOSE_FILE" ]; then
    fail "Compose-Datei $COMPOSE_FILE fehlt."
  fi
  read -r -p "Service (leer = alle): " svc
  read -r -p "Ohne Prefix anzeigen? (y/N): " nopfx
  local flags=""
  if [[ "$nopfx" =~ ^[Yy]$ ]]; then
    flags="--no-log-prefix"
  fi
  eval $DC_CMD logs -f --tail=100 $flags ${svc:-}
}

# --- Menu --------------------------------------------------------------------
main_menu() {
  while true; do
    print_header
    printf "%s\n" \
      "${YELLOW}┌──────────────────────────────────────────────┐${NC}" \
      "${YELLOW}│${NC} 1) 🔍 API Health Check (single)             ${YELLOW}│${NC}" \
      "${YELLOW}│${NC} 2) 📡 API Monitoring Loop                 ${YELLOW}│${NC}" \
      "${YELLOW}│${NC} 3) 🧪 Endpoint Tests                      ${YELLOW}│${NC}" \
      "${YELLOW}│${NC} 4) 📚 API Docs generieren                 ${YELLOW}│${NC}" \
      "${YELLOW}│${NC} 5) 💾 Git Savepoint (add/commit/push)    ${YELLOW}│${NC}" \
      "${YELLOW}│${NC} 6) 📜 Docker Logs (optional no-prefix)   ${YELLOW}│${NC}" \
      "${YELLOW}│${NC} 0) ❌ Beenden                             ${YELLOW}│${NC}" \
      "${YELLOW}└──────────────────────────────────────────────┘${NC}"
    read -r -p "Auswahl: " choice
    case "$choice" in
      1) health_single; read -r -p "Weiter mit Enter..." _ ;;
      2) health_monitor ;;
      3) test_endpoints; read -r -p "Weiter mit Enter..." _ ;;
      4) generate_api_docs; read -r -p "Weiter mit Enter..." _ ;;
      5) git_savepoint; read -r -p "Weiter mit Enter..." _ ;;
      6) tail_logs ;;
      0) exit 0 ;;
      *) warn "Ungültige Auswahl"; sleep 1 ;;
    esac
  done
}

# --- Entry -------------------------------------------------------------------
check_prereqs
main_menu
