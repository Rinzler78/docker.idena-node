#!/bin/sh
set -eu

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

CONFIG_FILE="/datadir/config.json"
# Space-separated list (no bash arrays needed)
REQUIRED_COMMANDS="getent adduser chpasswd timeout grep sed mv chmod mkdir mktemp mkfifo tee rm"

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
if [ ! -s "$SUBSCRIPTIONS_FILE" ]; then
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

run_node_once() {
    run_log="$(mktemp /tmp/idena-node-run-log.XXXXXX)"
    run_fifo="${run_log}.fifo"

    mkfifo "$run_fifo"
    tee "$run_log" < "$run_fifo" &
    tee_pid=$!

    log "Starting idena-node for ${RUN_TIMEOUT}s..."
    set +e
    timeout "${RUN_TIMEOUT}s" idena-node --config="$CONFIG_FILE" > "$run_fifo" 2>&1
    node_exit=$?
    set -e

    rm -f "$run_fifo"
    wait "$tee_pid"
    LAST_RUN_LOG="$run_log"
    return "$node_exit"
}

should_auto_recover_chain_db() {
    log_file=$1
    [ -f "$log_file" ] || return 1
    grep -Fq 'panic: Value missing for hash' "$log_file" || return 1
    grep -Fq 'github.com/cosmos/iavl.(*nodeDB).GetNode' "$log_file" || return 1
}

backup_corrupt_chain_db() {
    chain_db_dir="/datadir/idenachain.db"
    [ -e "$chain_db_dir" ] || return 1

    recovery_dir="/datadir/recovery"
    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup_path="$recovery_dir/idenachain.db.corrupt-$timestamp"

    mkdir -p "$recovery_dir"
    mv "$chain_db_dir" "$backup_path"
    log "Detected corrupted Idena chain database. Backed up '$chain_db_dir' to '$backup_path' and retrying once."
}

attempt=1
max_attempts=2

while [ "$attempt" -le "$max_attempts" ]; do
    if run_node_once; then
        node_exit=0
        rm -f "$LAST_RUN_LOG"
        exit 0
    else
        node_exit=$?
    fi

    if [ "$attempt" -eq 1 ] && should_auto_recover_chain_db "$LAST_RUN_LOG"; then
        if backup_corrupt_chain_db; then
            rm -f "$LAST_RUN_LOG"
            attempt=$((attempt + 1))
            continue
        fi
    fi

    rm -f "$LAST_RUN_LOG"
    exit "$node_exit"
done
