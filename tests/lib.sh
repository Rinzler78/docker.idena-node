#!/bin/bash
set -euo pipefail

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

fail() {
  log "[FAIL] $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "$1 is required but not installed."
}

repo_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

build_test_image() {
  local image_name="$1"
  local root
  root="$(repo_root)"
  log "Building Docker image '$image_name'..."
  docker build "$root" --tag "$image_name"
}

