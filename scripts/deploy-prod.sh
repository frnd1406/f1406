#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_DIR="$ROOT_DIR/infrastructure"
ENV_FILE="$INFRA_DIR/.env.prod"
COMPOSE_FILE="$INFRA_DIR/docker-compose.prod.yml"
PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$INFRA_DIR")}"
NETWORK_NAME="${PROJECT_NAME}_nas-network"
DC_CMD="docker compose --env-file \"$ENV_FILE\" -f \"$COMPOSE_FILE\""

fail() { echo -e "${RED}❌ $*${NC}" >&2; exit 1; }
info() { echo -e "${BLUE}ℹ️  $*${NC}"; }
ok()   { echo -e "${GREEN}✅ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $*${NC}"; }

require_cmd() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || fail "Befehl fehlt: $cmd"
  done
}

smart_wait_pg() {
  local retries=30 delay=2
  info "Warte auf Postgres (pg_isready)..."
  for ((i=1; i<=retries; i++)); do
    if eval $DC_CMD exec -T postgres pg_isready -U nas_user -d nas_db -h localhost >/dev/null 2>&1; then
      ok "Postgres ist bereit."
      return 0
    fi
    echo -e "${YELLOW}  Versuch $i/$retries...${NC}"
    sleep "$delay"
  done
  fail "Postgres wurde nicht bereit."
}

smart_wait_api() {
  local retries=30 delay=2
  info "Warte auf API (/health) über Netzwerk ${NETWORK_NAME}..."
  for ((i=1; i<=retries; i++)); do
    if docker run --rm --network "$NETWORK_NAME" curlimages/curl:8.9.1 -fsS http://api:8080/health >/dev/null 2>&1; then
      ok "API ist erreichbar."
      return 0
    fi
    echo -e "${YELLOW}  Versuch $i/$retries...${NC}"
    sleep "$delay"
  done
  fail "API (/health) nicht erreichbar."
}

apply_db_seed_if_reset() {
  local do_reset=$1
  if [ "$do_reset" != "true" ]; then
    return 0
  fi
  info "Starte DB-Init (Clean Slate)..."
  if [ -f "$INFRA_DIR/db/init.sql" ]; then
    eval $DC_CMD exec -T postgres psql -U nas_user -d nas_db < "$INFRA_DIR/db/init.sql"
  fi
  if [ -f "$INFRA_DIR/db/migrations/001_add_email_verification.sql" ]; then
    eval $DC_CMD exec -T postgres psql -U nas_user -d nas_db < "$INFRA_DIR/db/migrations/001_add_email_verification.sql"
  fi
  ok "DB-Init abgeschlossen."
}

prompt_reset() {
  read -r -p "Datenbank komplett zurücksetzen? (y/N): " ans
  [[ "$ans" =~ ^[Yy]$ ]] && echo "true" || echo "false"
}

# --- Entry -------------------------------------------------------------------
require_cmd docker curl
[ -f "$ENV_FILE" ] || fail ".env.prod fehlt unter $ENV_FILE"
[ -f "$COMPOSE_FILE" ] || fail "docker-compose.prod.yml fehlt unter $COMPOSE_FILE"

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}   🚀 NAS.AI Production Deployment               ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

DO_RESET=$(prompt_reset)

info "Stoppe laufende Container..."
if [ "$DO_RESET" = "true" ]; then
  eval $DC_CMD down -v --remove-orphans
else
  eval $DC_CMD down --remove-orphans
fi

info "Starte Compose (build + up)..."
eval $DC_CMD up -d --build

smart_wait_pg
apply_db_seed_if_reset "$DO_RESET"
smart_wait_api

info "Aktueller Status:"
eval $DC_CMD ps

ok "Deployment abgeschlossen."
echo -e "${YELLOW}Hinweis:${NC} Logs ansehen mit: ${BLUE}$DC_CMD logs -f --no-log-prefix${NC}"
