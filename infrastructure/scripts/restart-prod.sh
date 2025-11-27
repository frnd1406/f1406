#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${ROOT}/docker-compose.prod.yml"
ENV_FILE="${ROOT}/.env.prod"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: Env file not found at ${ENV_FILE}. Aborting."
  exit 1
fi

echo "Restarting production stack with ${COMPOSE_FILE}..."
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" down
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" up -d

echo "Done. Current status:"
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps
