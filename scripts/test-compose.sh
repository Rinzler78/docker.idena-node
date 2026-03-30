#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [--help]"
  echo ""
  echo "Run the full docker-compose validation suite."
  echo ""
  echo "Environment variables (all optional, defaults shown):"
  echo "  IDENA_USER_ACCOUNT_NAME     idenaUser"
  echo "  IDENA_USER_ACCOUNT_PASS     test-password"
  echo "  IDENA_IMAGE_NAME            idena-node:compose-local"
  echo "  RUN_TIMEOUT                 86400"
  echo "  IDENA_SSH_HOST_PORT         60022"
  echo "  IDENA_P2P_HOST_PORT         40405"
  echo "  IDENA_API_HOST_PORT         9999"
  exit 0
fi

export IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-test-password}"
export IDENA_USER_ACCOUNT_NAME="${IDENA_USER_ACCOUNT_NAME:-idenaUser}"
export RUN_TIMEOUT="${RUN_TIMEOUT:-86400}"

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

if command -v sshpass >/dev/null 2>&1; then
  log "Testing SSH connectivity via published port..."
  local_ssh_port="${IDENA_SSH_HOST_PORT:-60022}"
  ssh_connected=false
  for i in $(seq 1 10); do
    if sshpass -p "$IDENA_USER_ACCOUNT_PASS" \
         ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
         -p "$local_ssh_port" "$IDENA_USER_ACCOUNT_NAME@127.0.0.1" \
         echo "SSH connection successful" >/dev/null 2>&1; then
      ssh_connected=true
      break
    fi
    log "SSH not ready yet, retrying ($i/10)..."
    sleep 1
  done
  [ "$ssh_connected" = true ] || fail "Compose SSH connectivity test failed for user '$IDENA_USER_ACCOUNT_NAME'."
  log "SSH connectivity test passed."
fi

log "Compose tests completed."
