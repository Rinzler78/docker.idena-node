#!/bin/bash

# --------------------
# Variables
# --------------------
name=$1
if [ -z "$name" ]; then
    name="idena-node"
fi
# SSH user variables
IDENA_USER_ACCOUNT_NAME="idenaClient"
IDENA_USER_ACCOUNT_PASS="idenaClientPassword"
# Container execution timeout (in seconds)
RUN_TIMEOUT=120
# List of ports to test (format host:container)
PORTS="2222:22 40405:40405 9999:9999"

# Global variable for container ID
container_id=""

# --------------------
# Functions
# --------------------
# Function to build the Docker image
docker_build() {
    local image_name=$1
    docker build . --tag "$image_name"
    return $?
}

# Function to run the Docker container
docker_run() {
    local image_name=$1
    local ports_list="$2"
    local run_timeout=$3
    local user_name=$4
    local user_pass=$5
    # Build PORTS_MAPPING from ports_list
    local ports_mapping=""
    for mapping in $ports_list; do
      host_port=$(echo $mapping | cut -d: -f1)
      container_port=$(echo $mapping | cut -d: -f2)
      ports_mapping="$ports_mapping -p $host_port:$container_port"
    done
    echo "docker run \\
      --env RUN_TIMEOUT=$run_timeout \\
      -it \\
      --env IDENA_USER_ACCOUNT_NAME=$user_name \\
      --env IDENA_USER_ACCOUNT_PASS=$user_pass \\
      $ports_mapping \\
      --rm -d $image_name"
    container_id=$(docker run \
      --env RUN_TIMEOUT=$run_timeout \
      -it \
      --env IDENA_USER_ACCOUNT_NAME=$user_name \
      --env IDENA_USER_ACCOUNT_PASS=$user_pass \
      $ports_mapping \
      --rm -d $image_name)
    return $?
}

# Function to check port mapping
check_port_mapping() {
    local all_ok=true
    for mapping in $PORTS; do
        port_host=$(echo $mapping | cut -d: -f1)
        timeout 2 bash -c "</dev/tcp/127.0.0.1/$port_host" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "Port $port_host is exposed on host"
        else
            echo "Port $port_host is NOT exposed on host"
            all_ok=false
        fi
    done
    if [ "$all_ok" = true ]; then
        return 0
    else
        return 1
    fi
}

# Function to test SSH connection
check_ssh_connect() {
    local port=$1
    local user=$2
    local pass=$3
    echo "sshpass -p \"$pass\" ssh -o StrictHostKeyChecking=no -p $port $user@127.0.0.1 echo \"SSH connection successful\""
    for i in $(seq 1 $RUN_TIMEOUT); do
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p $port $user@127.0.0.1 echo "SSH connection successful"
        if [ $? -eq 0 ]; then
            return 0
        fi
        sleep 1
    done
    echo "SSH connection failed"
    return 1
}

# Function to delete the container if still running
docker_delete() {
    if [ ! -z "$container_id" ]; then
        docker rm -f $container_id
    fi
}

# --------------------
# Main implementation
# --------------------
# Build specified tag and run for 3s
if docker_build $name; then
    # Run container in detached mode
    if docker_run "$name" "$PORTS" "$RUN_TIMEOUT" "$IDENA_USER_ACCOUNT_NAME" "$IDENA_USER_ACCOUNT_PASS"; then
        if check_port_mapping; then
            SSH_HOST_PORT=$(echo $PORTS | tr ' ' '\n' | grep ':22$' | cut -d: -f1)
            if check_ssh_connect $SSH_HOST_PORT $IDENA_USER_ACCOUNT_NAME $IDENA_USER_ACCOUNT_PASS; then
                echo "Success"
            fi
        fi
    fi
fi

# Catch error code. 124 is success code
returnedCode=$?

docker_delete

if [ $returnedCode -eq 124 ]; then
    echo "Success"
    exit 0
fi

exit $returnedCode