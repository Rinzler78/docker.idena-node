#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker
require_command jq

ROOT="$(repo_root)"
cd "$ROOT"

IMAGE_NAME="idena-node:test-contract"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image_name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--image_name IMAGE_NAME]"
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
done

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  build_test_image "$IMAGE_NAME"
else
  log "Using existing image '$IMAGE_NAME'."
fi

log "Checking image environment contract..."
env_json=$(docker image inspect "$IMAGE_NAME" --format '{{json .Config.Env}}')
printf '%s\n' "$env_json" | jq -e 'map(startswith("IDENA_USER_ACCOUNT_PASS=")) | any | not' >/dev/null || fail "Image still persists IDENA_USER_ACCOUNT_PASS in Config.Env."

log "Checking exposed ports metadata..."
ports_json=$(docker image inspect "$IMAGE_NAME" --format '{{json .Config.ExposedPorts}}')
printf '%s\n' "$ports_json" | jq -e 'has("22/tcp") and has("40405/tcp") and has("9009/tcp")' >/dev/null || fail "Image exposed ports metadata is incomplete."

container_id=""
cleanup() {
  if [ -n "$container_id" ]; then
    docker rm -f "$container_id" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

log "Running container to verify runtime contract..."
container_id=$(docker run -d --rm \
  --env RUN_TIMEOUT=60 \
  --env IDENA_USER_ACCOUNT_NAME=idenaClient \
  --env IDENA_USER_ACCOUNT_PASS=idenaClientPassword \
  "$IMAGE_NAME")

for i in $(seq 1 30); do
  health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_id")
  if [ "$health_status" = "healthy" ]; then
    break
  fi
  if [ "$health_status" = "unhealthy" ]; then
    fail "Container became unhealthy during contract test."
  fi
  sleep 1
done

health_status=$(docker inspect --format='{{.State.Health.Status}}' "$container_id")
[ "$health_status" = "healthy" ] || fail "Container did not become healthy within the expected time."

version=$(docker exec "$container_id" bash -lc 'cd / && /tools/version.remote.sh')
printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail "version.remote.sh did not return a valid semver from /."

docker exec "$container_id" bash -lc 'echo > /dev/tcp/127.0.0.1/22' >/dev/null 2>&1 || fail "SSH port 22 is not reachable inside the container."

log "Image contract tests passed."

