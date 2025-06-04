#!/bin/bash
set -euo pipefail

# Logging function with timestamp
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

# Trap to catch errors
trap 'log "An error occurred. Exiting." >&2' ERR

# Configurable variables
IDENA_NODE_BINARY="/bin/idena-node"
TMP_FILENAME="tmp.idena-node"

# Check required commands
REQUIRED_COMMANDS=(wget chmod mv curl jq)
for cmd in "${REQUIRED_COMMANDS[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || { log "$cmd is required but not installed."; exit 1; }
done

# Check required scripts
for script in /tools/version.remote.sh /tools/version.locale.sh; do
  [ -x "$script" ] || { log "$script is required and must be executable."; exit 1; }
done

# Get remote version
remoteVersion=$(/tools/version.remote.sh)
log "Remote version: $remoteVersion"

if [ -z "$remoteVersion" ]; then
    log "ERROR: Unable to retrieve remote version. Aborting update."
    exit 1
fi

# Get current version
if [ -x "$IDENA_NODE_BINARY" ]; then
    currentVersion=$(/tools/version.locale.sh)
else
    currentVersion=""
fi
log "Current version: $currentVersion"

# Download and update if needed
if [ -z "$remoteVersion" ] || [ "$remoteVersion" != "$currentVersion" ]; then
    log "Downloading idena-node version $remoteVersion ..."
    latestReleaseUrl=$(curl -s "$(cat /tools/url.releases.txt)" | jq -r '.assets[]? | select(type == "object" and .name? and (.name | type == "string") and (.name | startswith("idena-node-linux-")) and (.name | contains("aarch64") | not) and (.name | contains(".tar.gz") | not) and (.name | contains(".md5") | not)) | .browser_download_url')
    log "Latest release URL: $latestReleaseUrl"
    if [ -z "$latestReleaseUrl" ]; then
        log "ERROR: Unable to retrieve the download URL for the latest release. The release might not have a 'linux-amd64' asset, or the GitHub API response structure might have changed."
        exit 1
    fi
    wget --output-document="$TMP_FILENAME" "$latestReleaseUrl" 2>/dev/null
    if [ -f "$TMP_FILENAME" ]; then
        chmod +x "$TMP_FILENAME"
        log "Moving $TMP_FILENAME to $IDENA_NODE_BINARY ..."
        mv "$TMP_FILENAME" "$IDENA_NODE_BINARY"
        log "idena-node updated to: $remoteVersion"
    else
        log "Download failed"
        exit 1
    fi
else
    log "idena-node is up to date"
fi