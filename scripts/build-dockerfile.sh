#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

IMAGE_NAME="${IMAGE_NAME:-idena-node:latest}"

build_dockerfile_image "$IMAGE_NAME"
