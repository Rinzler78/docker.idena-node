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

build_dockerfile_image() {
  require_command docker
  local image_name="$1"
  local build_arg_name="${IDENA_USER_ACCOUNT_NAME:-idenaClient}"
  local build_arg_pass="${IDENA_USER_ACCOUNT_PASS:-idenaClientPassword}"
  local root
  root="$(repo_root)"
  cd "$root"
  log "Building Docker image '$image_name' from Dockerfile..."
  docker build . --tag "$image_name" \
    --build-arg IDENA_USER_ACCOUNT_NAME="$build_arg_name" \
    --build-arg IDENA_USER_ACCOUNT_PASS="$build_arg_pass"
  log "Dockerfile build completed."
}

build_compose_services() {
  require_command docker
  local root
  root="$(repo_root)"
  cd "$root"
  export IDENA_IMAGE_NAME="${IDENA_IMAGE_NAME:-idena-node:compose-local}"
  export IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-build-only-password}"
  log "Building services from docker-compose.yml..."
  docker compose build
  log "Compose build completed."
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

port_is_free() {
  local port="$1"
  if timeout 1 bash -c "</dev/tcp/127.0.0.1/$port" >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

choose_free_port() {
  local start_port="$1"
  local end_port="$2"
  local reserved_ports="${3:-}"
  local port

  for port in $(seq "$start_port" "$end_port"); do
    case " $reserved_ports " in
      *" $port "*)
        continue
        ;;
    esac
    if port_is_free "$port"; then
      printf '%s\n' "$port"
      return 0
    fi
  done

  fail "No free port found in range ${start_port}-${end_port}."
}

assert_compose_config() {
  require_command docker
  local root
  root="$(repo_root)"
  cd "$root"

  log "Validating docker-compose defaults..."
  local default_config
  default_config=$(IDENA_USER_ACCOUNT_PASS=test-password docker compose config)
  printf '%s\n' "$default_config" | grep -q 'published: "60022"' || fail "Default SSH host port is not 60022."
  printf '%s\n' "$default_config" | grep -q 'published: "40405"' || fail "Default P2P host port is not 40405."
  printf '%s\n' "$default_config" | grep -q 'published: "9999"' || fail "Default API host port is not 9999."
  printf '%s\n' "$default_config" | grep -q 'type: volume' || fail "Default compose storage is not a Docker volume."
  printf '%s\n' "$default_config" | grep -q 'source: idena-node-data' || fail "Default compose volume name is not idena-node-data."
  printf '%s\n' "$default_config" | grep -q 'test:' || fail "Compose healthcheck is missing."
  printf '%s\n' "$default_config" | grep -q '/dev/tcp/localhost/22' || fail "Compose healthcheck does not probe SSH on port 22."
  printf '%s\n' "$default_config" | grep -q '/dev/tcp/localhost/9009' || fail "Compose healthcheck does not probe the API port 9009."

  log "Validating docker-compose port overrides..."
  local override_config
  override_config=$(IDENA_USER_ACCOUNT_PASS=test-password IDENA_SSH_HOST_PORT=16022 IDENA_P2P_HOST_PORT=24045 IDENA_API_HOST_PORT=19009 docker compose config)
  printf '%s\n' "$override_config" | grep -q 'published: "16022"' || fail "Overridden SSH host port was not applied."
  printf '%s\n' "$override_config" | grep -q 'published: "24045"' || fail "Overridden P2P host port was not applied."
  printf '%s\n' "$override_config" | grep -q 'published: "19009"' || fail "Overridden API host port was not applied."

  log "Compose configuration tests passed."
}

build_test_image() {
  local image_name="$1"
  build_dockerfile_image "$image_name"
}

assert_image_contract() {
  (
    require_command docker
    require_command jq
    local image_name="$1"
    local root
    root="$(repo_root)"
    cd "$root"

    log "Checking image environment contract..."
    local env_json
    env_json=$(docker image inspect "$image_name" --format '{{json .Config.Env}}')
    printf '%s\n' "$env_json" | jq -e 'map(startswith("IDENA_USER_ACCOUNT_PASS=")) | any | not' >/dev/null || fail "Image still persists IDENA_USER_ACCOUNT_PASS in Config.Env."

    log "Checking exposed ports metadata..."
    local ports_json
    ports_json=$(docker image inspect "$image_name" --format '{{json .Config.ExposedPorts}}')
    printf '%s\n' "$ports_json" | jq -e 'has("22/tcp") and has("40405/tcp") and has("9009/tcp")' >/dev/null || fail "Image exposed ports metadata is incomplete."

    local container_id=""
    cleanup_contract_container() {
      if [ -n "$container_id" ]; then
        docker rm -f "$container_id" >/dev/null 2>&1 || true
      fi
    }
    trap cleanup_contract_container EXIT

    log "Running container to verify runtime contract..."
    container_id=$(docker run -d --rm \
      --env RUN_TIMEOUT=60 \
      --env IDENA_USER_ACCOUNT_NAME="${IDENA_USER_ACCOUNT_NAME:-idenaClient}" \
      --env IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-idenaClientPassword}" \
      "$image_name")

    wait_for_health "$container_id" 30

    local version
    version=$(docker exec "$container_id" bash -lc 'cd / && /tools/version.remote.sh')
    printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail "version.remote.sh did not return a valid semver from /."

    docker exec "$container_id" bash -lc 'echo > /dev/tcp/127.0.0.1/22' >/dev/null 2>&1 || fail "SSH port 22 is not reachable inside the container."

    log "Image contract tests passed."
  )
}

run_quick_dockerfile_test() {
  (
    require_command docker
    require_command sshpass
    require_command timeout
    local image_name="$1"
    local allow_internal_ssh_fallback="${2:-false}"
    local run_timeout="${RUN_TIMEOUT:-120}"
    local ports="${TEST_PORTS:-}"
    local idena_user="${IDENA_USER_ACCOUNT_NAME:-idenaClient}"
    local idena_pass="${IDENA_USER_ACCOUNT_PASS:-idenaClientPassword}"
    local container_id=""

    cleanup_quick_container() {
      if [ -n "$container_id" ]; then
        docker rm -f "$container_id" >/dev/null 2>&1 || true
        echo "Container $container_id deleted."
      fi
    }
    trap cleanup_quick_container EXIT

    if [ -z "$ports" ]; then
      local reserved_ports=""
      local ssh_host_port p2p_host_port api_host_port
      ssh_host_port=$(choose_free_port 62022 62122 "$reserved_ports")
      reserved_ports="$reserved_ports $ssh_host_port"
      p2p_host_port=$(choose_free_port 44045 44145 "$reserved_ports")
      reserved_ports="$reserved_ports $p2p_host_port"
      api_host_port=$(choose_free_port 19099 19199 "$reserved_ports")
      ports="$ssh_host_port:22 $p2p_host_port:40405 $api_host_port:9009"
    fi

    local ports_mapping=""
    local mapping
    for mapping in $ports; do
      local host_port container_port
      host_port=$(echo "$mapping" | cut -d: -f1)
      container_port=$(echo "$mapping" | cut -d: -f2)
      ports_mapping="$ports_mapping -p $host_port:$container_port"
    done

    echo "[INFO] Running Docker container..."
    echo "docker run \\
      --env RUN_TIMEOUT=$run_timeout \\
      -it \\
      --env IDENA_USER_ACCOUNT_NAME=$idena_user \\
      --env IDENA_USER_ACCOUNT_PASS=*** \\
      $ports_mapping \\
      --rm -d $image_name"
    container_id=$(docker run \
      --env RUN_TIMEOUT="$run_timeout" \
      -it \
      --env IDENA_USER_ACCOUNT_NAME="$idena_user" \
      --env IDENA_USER_ACCOUNT_PASS="$idena_pass" \
      $ports_mapping \
      --rm -d "$image_name")
    [ -n "$container_id" ] || fail "Docker run failed: container not started."
    echo "[INFO] Container started: $container_id"

    echo "[INFO] Waiting for container to become healthy..."
    wait_for_health "$container_id" "$run_timeout"
    echo "[SUCCESS] Container is healthy."

    local version
    version=$(docker exec "$container_id" /tools/version.locale.sh)
    [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "version.locale.sh did not return a valid version: $version"
    echo "[SUCCESS] version.locale.sh returned a valid version: $version"

    echo "[INFO] Testing update logic..."
    local remote_version
    remote_version=$(docker exec "$container_id" /tools/version.remote.sh)
    echo "[INFO] Local version: $version"
    echo "[INFO] Remote version: $remote_version"
    if [ "$version" = "$remote_version" ]; then
      echo "[SUCCESS] Local and remote versions match."
    else
      echo "[INFO] Local and remote versions differ. Update needed."
    fi

    echo "[INFO] Testing SSH connection..."
    local ssh_port
    ssh_port=$(echo "$ports" | tr ' ' '\n' | grep ':22$' | cut -d: -f1)
    [ -n "$ssh_port" ] || fail "Could not determine published SSH host port."
    local host_port_accessible=false
    if timeout 1 bash -c "</dev/tcp/127.0.0.1/$ssh_port" >/dev/null 2>&1; then
      host_port_accessible=true
    fi

    if [ "$host_port_accessible" = true ]; then
      local ssh_connected=false
      local i
      for i in $(seq 1 10); do
        if sshpass -p "$idena_pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p "$ssh_port" "$idena_user@127.0.0.1" echo "SSH connection successful"; then
          ssh_connected=true
          break
        fi
        echo "[INFO] SSH not ready yet, retrying ($i/10)..."
        sleep 1
      done
      [ "$ssh_connected" = true ] || fail "SSH connection failed."
    else
      if [ "$allow_internal_ssh_fallback" = false ]; then
        fail "Published host SSH port $ssh_port is not reachable."
      fi
      echo "[WARN] Published host ports are not reachable in this Docker environment; falling back to internal SSH validation."
      docker exec "$container_id" bash -lc "echo > /dev/tcp/127.0.0.1/22 && getent passwd '$idena_user' >/dev/null" >/dev/null 2>&1 || fail "Internal SSH validation failed."
    fi
    echo "[SUCCESS] SSH connection test passed."

    echo "[INFO] Stopping container..."
    docker stop "$container_id"
    echo "[SUCCESS] All tests passed."
  )
}

run_update_fallback_test() {
  (
    require_command docker
    local image_name="$1"
    local container_id=""

    cleanup_update_container() {
      if [ -n "$container_id" ]; then
        docker rm -f "$container_id" >/dev/null 2>&1 || true
        echo "Container $container_id deleted."
      fi
    }
    trap cleanup_update_container EXIT

    echo "[INFO] Running container for update fallback test..."
    container_id=$(docker run -d --rm \
      --env RUN_TIMEOUT=120 \
      --env IDENA_USER_ACCOUNT_NAME="${IDENA_USER_ACCOUNT_NAME:-idenaClient}" \
      --env IDENA_USER_ACCOUNT_PASS="${IDENA_USER_ACCOUNT_PASS:-idenaClientPassword}" \
      "$image_name")
    [ -n "$container_id" ] || fail "Docker run failed: container not started for fallback test."

    echo "[INFO] Waiting for fallback test container to become healthy..."
    wait_for_health "$container_id" 30

    local before_version after_version
    before_version=$(docker exec "$container_id" /tools/version.locale.sh)
    [[ $before_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Initial version is invalid in fallback test: $before_version"

    echo "[INFO] Forcing release API failure and re-running update.sh..."
    docker exec "$container_id" bash -lc "printf '%s\n' 'http://127.0.0.1:9/releases/latest' > /tools/url.releases.txt && /tools/update.sh"

    after_version=$(docker exec "$container_id" /tools/version.locale.sh)
    [ "$before_version" = "$after_version" ] || fail "Fallback update changed the installed version ($before_version -> $after_version)."

    docker exec "$container_id" test ! -e /bin/idena-node.prev || fail "Fallback update left an unexpected backup binary behind."

    echo "[SUCCESS] Update fallback test passed."
  )
}
