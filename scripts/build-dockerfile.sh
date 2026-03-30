#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

IMAGE_NAME="${IMAGE_NAME:-idena-node:latest}"

log "Building Docker image '$IMAGE_NAME' from Dockerfile..."
docker build . --tag "$IMAGE_NAME"
log "Dockerfile build completed."

