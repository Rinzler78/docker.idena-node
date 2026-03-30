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

wait_for_health() {
  local container_id="$1"
  local timeout_seconds="${2:-60}"

  for i in $(seq 1 "$timeout_seconds"); do
    local health_status
    health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_id")
    if [ "$health_status" = "healthy" ]; then
      return 0
    fi
    if [ "$health_status" = "unhealthy" ]; then
      fail "Container $container_id became unhealthy."
    fi
    sleep 1
  done

  fail "Container $container_id did not become healthy within ${timeout_seconds}s."
}
