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

# Get current version early so startup can keep using the embedded binary if
# the remote release API is temporarily unavailable or rate-limited.
if [ -x "$IDENA_NODE_BINARY" ]; then
    currentVersion=$(/tools/version.locale.sh)
else
    currentVersion=""
fi
log "Current version: $currentVersion"

# Get remote version
if remoteVersion=$(/tools/version.remote.sh); then
    log "Remote version: $remoteVersion"
else
    if [ -n "$currentVersion" ]; then
        log "Remote version lookup failed. Keeping current version: $currentVersion"
        exit 0
    fi
    log "ERROR: Unable to retrieve remote version and no local binary is available."
    exit 1
fi

if [ -z "$remoteVersion" ]; then
    if [ -n "$currentVersion" ]; then
        log "Remote version is empty. Keeping current version: $currentVersion"
        exit 0
    fi
    log "ERROR: Unable to retrieve remote version. Aborting update."
    exit 1
fi

# Download and update if needed
if [ -z "$remoteVersion" ] || [ "$remoteVersion" != "$currentVersion" ]; then
    log "Downloading idena-node version $remoteVersion ..."
    if ! latestReleaseUrl=$(curl -s -f "$(cat /tools/url.releases.txt)" | jq -r '.assets[]? | select(type == "object" and .name? and (.name | type == "string") and (.name | startswith("idena-node-linux-")) and (.name | contains("aarch64") | not) and (.name | contains(".tar.gz") | not) and (.name | contains(".md5") | not)) | .browser_download_url'); then
        if [ -n "$currentVersion" ]; then
            log "Failed to resolve latest release URL. Keeping current version: $currentVersion"
            exit 0
        fi
        log "ERROR: Unable to query the latest release metadata."
        exit 1
    fi
    log "Latest release URL: $latestReleaseUrl"
    if [ -z "$latestReleaseUrl" ]; then
        if [ -n "$currentVersion" ]; then
            log "Latest release URL is empty. Keeping current version: $currentVersion"
            exit 0
        fi
        log "ERROR: Unable to retrieve the download URL for the latest release. The release might not have a 'linux-amd64' asset, or the GitHub API response structure might have changed."
        exit 1
    fi
    rm -f "$TMP_FILENAME"
    wget --output-document="$TMP_FILENAME" "$latestReleaseUrl" 2>/dev/null || true
    if [ -f "$TMP_FILENAME" ]; then
        chmod +x "$TMP_FILENAME"
        log "Moving $TMP_FILENAME to $IDENA_NODE_BINARY ..."
        mv "$TMP_FILENAME" "$IDENA_NODE_BINARY"
        log "idena-node updated to: $remoteVersion"
    else
        if [ -n "$currentVersion" ]; then
            log "Download failed. Keeping current version: $currentVersion"
            exit 0
        fi
        log "Download failed"
        exit 1
    fi
else
    log "idena-node is up to date"
fi
