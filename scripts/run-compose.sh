#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

[ -n "${IDENA_USER_ACCOUNT_PASS:-}" ] || fail "Set IDENA_USER_ACCOUNT_PASS before running docker compose."

log "Starting services from docker-compose.yml..."
docker compose up -d
log "Compose run completed."

