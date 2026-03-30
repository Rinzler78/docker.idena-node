#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker
require_command jq
require_command sshpass
require_command timeout

ROOT="$(repo_root)"
cd "$ROOT"

IMAGE_NAME="${IMAGE_NAME:-idena-node:test-suite}"
ALLOW_INTERNAL_SSH_FALLBACK="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image_name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    --allow-internal-ssh-fallback)
      ALLOW_INTERNAL_SSH_FALLBACK="true"
      shift
      ;;
    --help)
      echo "Usage: $0 [--image_name IMAGE_NAME] [--allow-internal-ssh-fallback]"
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

log "Testing Dockerfile workflow with image '$IMAGE_NAME'..."
build_test_image "$IMAGE_NAME"
assert_image_contract "$IMAGE_NAME"
run_quick_dockerfile_test "$IMAGE_NAME" "$ALLOW_INTERNAL_SSH_FALLBACK"
log "Dockerfile tests completed."
