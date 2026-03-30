#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

IMAGE_NAME="${IMAGE_NAME:-idena-node:latest}"
export IDENA_USER_ACCOUNT_NAME="${IDENA_USER_ACCOUNT_NAME:-idenaClient}"
export IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-idenaClientPassword}"

build_dockerfile_image "$IMAGE_NAME"
