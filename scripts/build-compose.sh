#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

export IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-build-only-password}"

log "Building services from docker-compose.yml..."
docker compose build
log "Compose build completed."

