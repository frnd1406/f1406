#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="${ROOT}/bin/api"
LOG="$(mktemp)"

if [[ ! -x "${BIN}" ]]; then
  echo "ERROR: API binary not found at ${BIN}. Build it first (go build -o bin/api ./src)."
  exit 1
fi

export DATABASE_URL="postgres://invalid:invalid@localhost:5432/invalid?sslmode=disable"
export JWT_SECRET="0123456789abcdef0123456789abcdef"
export MONITORING_TOKEN="monitoring-token-dev-123456"
export REDIS_URL="localhost:6379"
export ENV="development"

set +e
timeout 5s "${BIN}" >"${LOG}" 2>&1
code=$?
set -e

if [[ ${code} -eq 124 ]]; then
  echo "ERROR: API did not fail fast (timeout). Log:"
  cat "${LOG}"
  exit 1
fi

if [[ ${code} -eq 0 ]]; then
  echo "ERROR: API started successfully with invalid DATABASE_URL (expected failure). Log:"
  cat "${LOG}"
  exit 1
fi

echo "OK: API exited with code ${code} as expected for invalid DATABASE_URL."
echo "Log tail:"
tail -n 10 "${LOG}"
