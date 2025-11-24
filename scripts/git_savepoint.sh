#!/usr/bin/env bash

set -euo pipefail

echo "==> Checking for git..."
if ! command -v git >/dev/null 2>&1; then
  echo "git is not installed. Please install git and rerun."
  exit 1
fi

if [ ! -d .git ]; then
  echo "==> Initializing git repository"
  git init
else
  echo "==> Git repository already initialized"
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
  echo "==> Ensuring main branch"
  git branch -M main || true
  echo "==> Pushing to origin/main"
  git push -u origin main
else
  echo "==> No origin remote configured; skipping push"
fi
