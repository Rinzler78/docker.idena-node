#!/bin/sh
set -eu

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

CONFIG_FILE="/datadir/config.json"
# Space-separated list (no bash arrays needed)
REQUIRED_COMMANDS="getent adduser chpasswd timeout grep sed mv chmod"

: "${IDENA_USER_ACCOUNT_NAME:?IDENA_USER_ACCOUNT_NAME is not set}"
: "${IDENA_USER_ACCOUNT_PASS:?IDENA_USER_ACCOUNT_PASS is not set}"
: "${RUN_TIMEOUT:?RUN_TIMEOUT is not set}"

for cmd in $REQUIRED_COMMANDS; do
  command -v "$cmd" >/dev/null 2>&1 || { log "$cmd is required but not installed."; exit 1; }
done

if ! getent passwd "$IDENA_USER_ACCOUNT_NAME" > /dev/null; then
    log "Creating user: $IDENA_USER_ACCOUNT_NAME"
    adduser -D -s /bin/sh "$IDENA_USER_ACCOUNT_NAME"
    echo "$IDENA_USER_ACCOUNT_NAME:$IDENA_USER_ACCOUNT_PASS" | chpasswd
fi

if [ ! -f "$CONFIG_FILE" ]; then
    log "Creating $CONFIG_FILE"
    echo '{ "IpfsConf": { "Profile": "server" } }' > "$CONFIG_FILE"
fi

SUBSCRIPTIONS_FILE="/datadir/subscriptions/subscriptions.json"
if [ ! -f "$SUBSCRIPTIONS_FILE" ]; then
    mkdir -p "$(dirname "$SUBSCRIPTIONS_FILE")"
    echo '[]' > "$SUBSCRIPTIONS_FILE"
fi
log "Starting SSH server..."
if command -v service >/dev/null 2>&1 && [ -f /etc/init.d/dropbear ]; then
    service dropbear start
else
    mkdir -p /etc/dropbear
    dropbear -R -p 22
fi

log "Updating idena-node binary..."
/tools/update.sh

log "Starting idena-node for ${RUN_TIMEOUT}s..."
timeout "${RUN_TIMEOUT}s" idena-node --config="$CONFIG_FILE"
