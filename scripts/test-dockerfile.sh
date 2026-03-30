#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

IMAGE_NAME="${IMAGE_NAME:-idena-node:test-suite}"

log "Testing Dockerfile workflow with image '$IMAGE_NAME'..."
"$ROOT/tests/image_contract_test.sh" --image_name "$IMAGE_NAME"
"$ROOT/quick_test.sh" --image_name "$IMAGE_NAME" --allow-internal-ssh-fallback
log "Dockerfile tests completed."

