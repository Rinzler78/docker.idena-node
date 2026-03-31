#!/bin/bash
set -euo pipefail

# Logging function with timestamp
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

# Trap to catch errors and print a custom message
trap 'log "An error occurred. Exiting." >&2' ERR

# Configurable variables
CONFIG_FILE="/datadir/config.json"
REQUIRED_COMMANDS=(getent useradd chpasswd service timeout wget grep sed mv chmod)

# Check required environment variables
: "${IDENA_USER_ACCOUNT_NAME:?IDENA_USER_ACCOUNT_NAME is not set}"
: "${IDENA_USER_ACCOUNT_PASS:?IDENA_USER_ACCOUNT_PASS is not set}"
: "${RUN_TIMEOUT:?RUN_TIMEOUT is not set}"

# Check required commands
for cmd in "${REQUIRED_COMMANDS[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || { log "$cmd is required but not installed."; exit 1; }
done

# Create user for ssh connection if not exists
if ! getent passwd "$IDENA_USER_ACCOUNT_NAME" > /dev/null; then
    log "Creating user: $IDENA_USER_ACCOUNT_NAME"
    useradd -ms /bin/bash "$IDENA_USER_ACCOUNT_NAME"
    echo "$IDENA_USER_ACCOUNT_NAME:$IDENA_USER_ACCOUNT_PASS" | chpasswd
    # Do NOT add user to sudo group for security reasons
fi

# Create default config file if not exists
if [ ! -f "$CONFIG_FILE" ]; then
    log "Creating $CONFIG_FILE"
    echo '{ "IpfsConf": { "Profile": "server" } }' > "$CONFIG_FILE"
fi

# Start ssh server
log "Starting SSH server..."
service dropbear start

# Update the embedded binary after SSH is available so operators can still
# inspect the container quickly if a remote release check is slow or flaky.
log "Updating idena-node binary..."
/tools/update.sh

# Start idena node with timeout
log "Starting idena-node for ${RUN_TIMEOUT}s..."
timeout "${RUN_TIMEOUT}s" idena-node --config="$CONFIG_FILE"
