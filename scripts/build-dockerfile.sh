#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [--help]"
  echo ""
  echo "Build the idena-node Docker image from the Dockerfile."
  echo ""
  echo "Environment variables (all optional, defaults shown):"
  echo "  IMAGE_NAME                  idena-node:latest"
  echo "  IDENA_USER_ACCOUNT_NAME     idenaClient   (Dockerfile build ARG)"
  echo "  IDENA_USER_ACCOUNT_PASS     idenaClientPassword   (Dockerfile build ARG)"
  exit 0
fi

IMAGE_NAME="${IMAGE_NAME:-idena-node:latest}"
export IDENA_USER_ACCOUNT_NAME="${IDENA_USER_ACCOUNT_NAME:-idenaClient}"
export IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-idenaClientPassword}"

build_dockerfile_image "$IMAGE_NAME"
