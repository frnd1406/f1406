#!/usr/bin/env bash

set -euo pipefail

# Reset helper: restarts API/WebUI, clears Redis cache, removes all alerts.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT_DIR}/infrastructure/docker-compose.dev.yml"

run() {
  echo "→ $*"
  "$@"
}

echo "Using compose file: ${COMPOSE_FILE}"

echo "[1/4] Ensure core services are up (api, webui, redis, postgres)..."
run docker compose -f "${COMPOSE_FILE}" up -d api webui redis postgres

echo "[2/4] Restart API and WebUI to refresh state..."
run docker compose -f "${COMPOSE_FILE}" restart api webui

echo "[3/4] Flush Redis cache..."
run docker compose -f "${COMPOSE_FILE}" exec redis redis-cli FLUSHALL

echo "[4/4] Truncate system alerts table..."
run docker compose -f "${COMPOSE_FILE}" exec postgres \
  psql -U nas_user -d nas_db -c "TRUNCATE TABLE system_alerts;"

echo "✅ Done. Web stack restarted, cache cleared, alerts wiped."
