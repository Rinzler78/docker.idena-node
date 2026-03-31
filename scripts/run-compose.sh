#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [--help]"
  echo ""
  echo "Build and start idena-node via docker compose."
  echo ""
  echo "Environment variables (all optional, defaults shown):"
  echo "  IDENA_IMAGE_NAME            idena-node:compose-local"
  echo "  IDENA_USER_ACCOUNT_NAME     idenaUser"
  echo "  IDENA_USER_ACCOUNT_PASS     idenaClientPassword"
  echo "  RUN_TIMEOUT                 86400"
  echo "  IDENA_SSH_HOST_PORT         60022"
  echo "  IDENA_P2P_HOST_PORT         40405"
  echo "  IDENA_API_HOST_PORT         9999"
  exit 0
fi

export IDENA_IMAGE_NAME="${IDENA_IMAGE_NAME:-idena-node:compose-local}"
export IDENA_USER_ACCOUNT_NAME="${IDENA_USER_ACCOUNT_NAME:-idenaUser}"
export IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-idenaClientPassword}"
export RUN_TIMEOUT="${RUN_TIMEOUT:-86400}"
export IDENA_SSH_HOST_PORT="${IDENA_SSH_HOST_PORT:-60022}"
export IDENA_P2P_HOST_PORT="${IDENA_P2P_HOST_PORT:-40405}"
export IDENA_API_HOST_PORT="${IDENA_API_HOST_PORT:-9999}"

build_compose_services

log "Starting services from docker-compose.yml..."
docker compose up -d
log "Compose run completed."
