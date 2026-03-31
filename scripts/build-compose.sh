#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

if [[ "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [--help]"
  echo ""
  echo "Build docker compose services for idena-node."
  echo ""
  echo "Environment variables (all optional, defaults shown):"
  echo "  IDENA_IMAGE_NAME            idena-node:compose-local"
  echo "  IDENA_USER_ACCOUNT_PASS     build-only-password"
  exit 0
fi

export IDENA_IMAGE_NAME="${IDENA_IMAGE_NAME:-idena-node:compose-local}"
export IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-build-only-password}"

build_compose_services
