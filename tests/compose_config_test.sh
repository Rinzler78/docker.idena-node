#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/lib.sh"

require_command docker

ROOT="$(repo_root)"
cd "$ROOT"

log "Validating docker-compose defaults..."
default_config=$(docker compose config)
printf '%s\n' "$default_config" | grep -q 'published: "60022"' || fail "Default SSH host port is not 60022."
printf '%s\n' "$default_config" | grep -q 'published: "40405"' || fail "Default P2P host port is not 40405."
printf '%s\n' "$default_config" | grep -q 'published: "9999"' || fail "Default API host port is not 9999."
printf '%s\n' "$default_config" | grep -q 'type: volume' || fail "Default compose storage is not a Docker volume."
printf '%s\n' "$default_config" | grep -q 'source: idena-node-data' || fail "Default compose volume name is not idena-node-data."

log "Validating docker-compose port overrides..."
override_config=$(IDENA_SSH_HOST_PORT=16022 IDENA_P2P_HOST_PORT=24045 IDENA_API_HOST_PORT=19009 docker compose config)
printf '%s\n' "$override_config" | grep -q 'published: "16022"' || fail "Overridden SSH host port was not applied."
printf '%s\n' "$override_config" | grep -q 'published: "24045"' || fail "Overridden P2P host port was not applied."
printf '%s\n' "$override_config" | grep -q 'published: "19009"' || fail "Overridden API host port was not applied."

log "Compose configuration tests passed."
