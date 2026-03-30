#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

export IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-test-password}"

cleanup() {
  docker compose down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

log "Testing docker-compose workflow..."
assert_compose_config
build_compose_services
docker compose config >/dev/null
docker compose up -d

container_id=$(docker compose ps -q idena-node)
[ -n "$container_id" ] || fail "Compose did not start the idena-node service."

log "Waiting for Compose service healthcheck to report healthy..."
wait_for_health "$container_id" 60

log "Compose tests completed."
