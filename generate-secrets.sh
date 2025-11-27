#!/usr/bin/env bash
set -euo pipefail

rand() {
  openssl rand -hex 32
}

echo "# Suggested secrets"
echo "JWT_SECRET=$(rand)"
echo "MONITORING_TOKEN=$(rand)"
echo "PENTESTER_API_TOKEN=$(rand)"
