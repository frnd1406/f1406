#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Checking for git..."
if ! command -v git >/dev/null 2>&1; then
  echo "git is not installed. Please install git and rerun."
  exit 1
fi

# Handle stale index locks
if [ -f .git/index.lock ]; then
  echo "==> Removing stale git index lock"
  rm -f .git/index.lock
fi

if [ ! -d .git ]; then
  echo "==> Initializing git repository"
  git init
else
  echo "==> Git repository already initialized"
fi

echo "==> Ensuring main branch"
git branch -M main || true

# Safety check: critical secrets must be ignored
if git check-ignore -q infrastructure/api/.env; then
  echo "==> Confirmed: infrastructure/api/.env is ignored"
else
  echo "ERROR: infrastructure/api/.env is not ignored. Fix .gitignore before proceeding."
  exit 1
fi

echo "==> Adding files"
git add .

echo "==> Current status"
git status

read -rp "Enter GitHub remote URL (leave empty to skip): " REMOTE_URL
if [ -n "${REMOTE_URL}" ]; then
  if git remote get-url origin >/dev/null 2>&1; then
    echo "==> Updating origin remote"
    git remote set-url origin "${REMOTE_URL}"
  else
    echo "==> Adding origin remote"
    git remote add origin "${REMOTE_URL}"
  fi
else
  echo "==> No remote provided, skipping remote setup"
fi

if [ -z "$(git status --short)" ]; then
  echo "==> Nothing to commit"
else
  echo "==> Creating commit"
  git commit -m "Phase 3 Savepoint"
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "==> Pushing to origin/main"
  git push -u origin main
else
  echo "==> No origin remote configured; skipping push"
fi
