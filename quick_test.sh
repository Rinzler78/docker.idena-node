#!/bin/bash

# --------------------
# Globals & Defaults
# --------------------
DEFAULT_IMAGE_NAME="idena-node"
DEFAULT_USER="idenaClient"
DEFAULT_PASS="idenaClientPassword"
DEFAULT_TIMEOUT=120
DEFAULT_PORTS="2222:22 40405:40405 9999:9999"

# Parameters (can be overridden by CLI)
image_name="$DEFAULT_IMAGE_NAME"
idena_user="$DEFAULT_USER"
idena_pass="$DEFAULT_PASS"
run_timeout=$DEFAULT_TIMEOUT
ports="$DEFAULT_PORTS"

container_id=""

# --------------------
# Helper: Print usage
# --------------------
print_help() {
    echo "Usage: $0 [--image IMAGE] [--user USER] [--pass PASS] [--timeout SECONDS] [--ports \"host:cont ...\"]"
    echo "\nOptions:"
    echo "  --image     Docker image name (default: $DEFAULT_IMAGE_NAME)"
    echo "  --user      SSH username (default: $DEFAULT_USER)"
    echo "  --pass      SSH password (default: $DEFAULT_PASS)"
    echo "  --timeout   Timeout in seconds (default: $DEFAULT_TIMEOUT)"
    echo "  --ports     Ports mapping (default: '$DEFAULT_PORTS')"
    echo "  --help      Show this help message"
}

# --------------------
# Parse CLI arguments
# --------------------
while [[ $# -gt 0 ]]; do
    case $1 in
        --image)
            image_name="$2"; shift 2;;
        --user)
            idena_user="$2"; shift 2;;
        --pass)
            idena_pass="$2"; shift 2;;
        --timeout)
            run_timeout="$2"; shift 2;;
        --ports)
            ports="$2"; shift 2;;
        --help)
            print_help; exit 0;;
        *)
            echo "Unknown option: $1"; print_help; exit 1;;
    esac
done

# --------------------
# Dependency check
# --------------------
for dep in docker sshpass; do
    if ! command -v $dep &>/dev/null; then
        echo "$dep is required but not installed. Aborting."
        exit 2
    fi
done

# --------------------
# Trap for cleanup
# --------------------
docker_delete() {
    if [ ! -z "$container_id" ]; then
        docker rm -f $container_id >/dev/null 2>&1
        echo "Container $container_id deleted."
    fi
}
trap docker_delete EXIT

# --------------------
# Function: Build Docker image
# --------------------
# Arguments: image_name
# Returns: 0 on success, 10 on failure
# --------------------
docker_build() {
    echo "[INFO] Building Docker image '$1'..."
    docker build . --tag "$1"
    if [ $? -ne 0 ]; then
        echo "[ERROR] Docker build failed."
        return 10
    fi
    return 0
}

# --------------------
# Function: Run Docker container
# --------------------
# Arguments: image_name ports timeout user pass
# Sets: container_id
# Returns: 0 on success, 11 on failure
# --------------------
docker_run() {
    local image_name="$1"
    local ports_list="$2"
    local run_timeout="$3"
    local user_name="$4"
    local user_pass="$5"
    local ports_mapping=""
    for mapping in $ports_list; do
        host_port=$(echo $mapping | cut -d: -f1)
        container_port=$(echo $mapping | cut -d: -f2)
        ports_mapping="$ports_mapping -p $host_port:$container_port"
    done
    echo "[INFO] Running Docker container..."
    # Mask password in log
    echo "docker run \\
      --env RUN_TIMEOUT=$run_timeout \\
      -it \\
      --env IDENA_USER_ACCOUNT_NAME=$user_name \\
      --env IDENA_USER_ACCOUNT_PASS=*** \\
      $ports_mapping \\
      --rm -d $image_name"
    container_id=$(docker run \
      --env RUN_TIMEOUT=$run_timeout \
      -it \
      --env IDENA_USER_ACCOUNT_NAME=$user_name \
      --env IDENA_USER_ACCOUNT_PASS=$user_pass \
      $ports_mapping \
      --rm -d $image_name)
    if [ -z "$container_id" ]; then
        echo "[ERROR] Docker run failed: container not started."
        return 11
    fi
    echo "[INFO] Container started: $container_id"
    return 0
}

# --------------------
# Function: Check port mapping
# --------------------
# Arguments: ports_list
# Returns: 0 if all ports are open, 12 otherwise
# --------------------
check_port_mapping() {
    local ports_list="$1"
    local all_ok=true
    for mapping in $ports_list; do
        port_host=$(echo $mapping | cut -d: -f1)
        timeout 2 bash -c "</dev/tcp/127.0.0.1/$port_host" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "[INFO] Port $port_host is exposed on host."
        else
            echo "[ERROR] Port $port_host is NOT exposed on host."
            all_ok=false
        fi
    done
    if [ "$all_ok" = true ]; then
        return 0
    else
        return 12
    fi
}

# --------------------
# Function: Test SSH connection
# --------------------
# Arguments: port user pass
# Returns: 0 on success, 13 on failure
# --------------------
check_ssh_connect() {
    local port=$1
    local user=$2
    local pass=$3
    echo "sshpass -p \"***\" ssh -o StrictHostKeyChecking=no -p $port $user@127.0.0.1 echo \"SSH connection successful\""
    for i in $(seq 1 $run_timeout); do
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p $port $user@127.0.0.1 echo "SSH connection successful"
        if [ $? -eq 0 ]; then
            return 0
        fi
        sleep 1
    done
    echo "[ERROR] SSH connection failed."
    return 13
}

# --------------------
# Main logic
# --------------------

if ! docker_build "$image_name"; then
    echo "[FAIL] Docker build failed."
    exit 10
fi

if ! docker_run "$image_name" "$ports" "$run_timeout" "$idena_user" "$idena_pass"; then
    echo "[FAIL] Docker run failed."
    exit 11
fi

if ! check_port_mapping "$ports"; then
    echo "[FAIL] Port mapping check failed."
    exit 12
fi

SSH_HOST_PORT=$(echo $ports | tr ' ' '\n' | grep ':22$' | cut -d: -f1)
if ! check_ssh_connect $SSH_HOST_PORT $idena_user $idena_pass; then
    echo "[FAIL] SSH connection test failed."
    exit 13
fi

echo "[SUCCESS] All tests passed."
exit 0