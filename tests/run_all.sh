#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker
require_command jq

ROOT="$(repo_root)"
cd "$ROOT"

IMAGE_NAME="idena-node:test-suite"

log "Running compose configuration checks..."
"$ROOT/tests/compose_config_test.sh"

log "Running image contract checks..."
"$ROOT/tests/image_contract_test.sh" --image_name "$IMAGE_NAME"

log "Running end-to-end quick test..."
"$ROOT/quick_test.sh" --image_name "$IMAGE_NAME"

log "All repository tests passed."

