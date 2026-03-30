#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

IMAGE_NAME="${IMAGE_NAME:-idena-node:latest}"
CONTAINER_NAME="${CONTAINER_NAME:-idena-node}"
SSH_HOST_PORT="${IDENA_SSH_HOST_PORT:-60022}"
P2P_HOST_PORT="${IDENA_P2P_HOST_PORT:-40405}"
API_HOST_PORT="${IDENA_API_HOST_PORT:-9999}"
USER_NAME="${IDENA_USER_ACCOUNT_NAME:-idenaUser}"
USER_PASS="${IDENA_USER_ACCOUNT_PASS:-idenaClientPassword}"
RUN_TIMEOUT="${RUN_TIMEOUT:-86400}"

build_dockerfile_image "$IMAGE_NAME"

log "Running Docker container '$CONTAINER_NAME' from image '$IMAGE_NAME'..."
docker run -d \
  --restart unless-stopped \
  --name "$CONTAINER_NAME" \
  -p "$SSH_HOST_PORT:22" \
  -p "$P2P_HOST_PORT:40405" \
  -p "$API_HOST_PORT:9009" \
  -v idena-node-data:/datadir \
  -e IDENA_USER_ACCOUNT_NAME="$USER_NAME" \
  -e IDENA_USER_ACCOUNT_PASS="$USER_PASS" \
  -e RUN_TIMEOUT="$RUN_TIMEOUT" \
  "$IMAGE_NAME"
log "Dockerfile run completed."
