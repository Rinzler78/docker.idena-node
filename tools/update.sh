#!/bin/sh
set -eu

log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

IDENA_NODE_BINARY="/bin/idena-node"
IDENA_NODE_BACKUP="${IDENA_NODE_BINARY}.prev"
RELEASES_API_URL="$(cat /tools/url.releases.txt)"
LOCK_DIR="/tmp/idena-node-update.lock"
WORK_DIR=""

REQUIRED_COMMANDS="awk chmod wget find grep sed md5sum mkdir mktemp mv rm tar uname"
for cmd in $REQUIRED_COMMANDS; do
  command -v "$cmd" >/dev/null 2>&1 || { log "$cmd is required but not installed."; exit 1; }
done

for script in /tools/version.remote.sh /tools/version.locale.sh; do
  [ -x "$script" ] || { log "$script is required and must be executable."; exit 1; }
done

cleanup() {
  if [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR"
  fi
  rmdir "$LOCK_DIR" >/dev/null 2>&1 || true
}

restore_backup() {
  if [ -f "$IDENA_NODE_BACKUP" ]; then
    log "Restoring previous idena-node binary from backup."
    mv -f "$IDENA_NODE_BACKUP" "$IDENA_NODE_BINARY"
  fi
}

trap cleanup EXIT

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  log "Another update is already running. Skipping concurrent update attempt."
  exit 0
fi

WORK_DIR="$(mktemp -d)"

if [ -x "$IDENA_NODE_BINARY" ]; then
  currentVersion=$(/tools/version.locale.sh)
else
  currentVersion=""
fi
log "Current version: ${currentVersion:-none}"

# Fetch the release JSON — busybox wget: -U for User-Agent, -T for timeout
# Retry loop replaces --tries/--waitretry
wget_release() {
  local i output
  for i in 1 2 3; do
    if output=$(wget -qO- -U "idena-node-updater/1.0" -T 20 "$RELEASES_API_URL" 2>/dev/null); then
      echo "$output"
      return 0
    fi
    [ "$i" -lt 3 ] && sleep 1
  done
  return 1
}

# Parse tag_name from release JSON (no jq needed)
parse_version() {
  echo "$1" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4 | sed 's/^v//'
}

# Get the download URL for the binary matching the current architecture.
# The URL itself ends with the asset filename so no JSON correlation needed.
select_asset_url() {
  local release_json="$1"
  local machine
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64)
      echo "$release_json" | grep -o '"browser_download_url":"[^"]*"' | cut -d'"' -f4 | \
        grep -E '/idena-node-linux-[0-9]+\.[0-9]+\.[0-9]+$' | head -1
      ;;
    aarch64|arm64)
      echo "$release_json" | grep -o '"browser_download_url":"[^"]*"' | cut -d'"' -f4 | \
        grep -E '/idena-node-linux-aarch64-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz$' | head -1
      ;;
    *)
      log "Unsupported architecture: $machine"
      return 1
      ;;
  esac
}

download_file() {
  local url="$1"
  local destination="$2"
  local i
  for i in 1 2 3; do
    if wget -qO "$destination" -U "idena-node-updater/1.0" -T 120 "$url" 2>/dev/null; then
      [ -s "$destination" ] && return 0
    fi
    [ "$i" -lt 3 ] && sleep 1
  done
  return 1
}

extract_candidate() {
  local package_path="$1"
  local asset_name="$2"
  local candidate_path="$WORK_DIR/idena-node.candidate"
  case "$asset_name" in
    *.tar.gz)
      tar -xzf "$package_path" -C "$WORK_DIR"
      local extracted_binary
      extracted_binary="$(find "$WORK_DIR" -maxdepth 2 -type f \( -name 'idena-node' -o -name 'idena-node-linux-*' \) | head -n1)"
      [ -n "$extracted_binary" ] || return 1
      mv "$extracted_binary" "$candidate_path"
      ;;
    *)
      mv "$package_path" "$candidate_path"
      ;;
  esac
  chmod +x "$candidate_path"
  echo "$candidate_path"
}

verify_md5() {
  local package_path="$1"
  local checksum_path="$2"
  local expected_md5
  expected_md5="$(grep -Eo '^[a-fA-F0-9]{32}' "$checksum_path" | head -n1)"
  [ -n "$expected_md5" ] || return 1
  local actual_md5
  actual_md5="$(md5sum "$package_path" | awk '{print $1}')"
  [ "$actual_md5" = "$expected_md5" ]
}

if release_json="$(wget_release)"; then
  remoteVersion="$(parse_version "$release_json")"
else
  if [ -n "$currentVersion" ]; then
    log "Remote version lookup failed. Keeping current version: $currentVersion"
    exit 0
  fi
  log "ERROR: Unable to retrieve remote version and no local binary is available."
  exit 1
fi

if [ -z "$remoteVersion" ] || [ "$remoteVersion" = "null" ]; then
  if [ -n "$currentVersion" ]; then
    log "Remote version is empty. Keeping current version: $currentVersion"
    exit 0
  fi
  log "ERROR: Unable to retrieve remote version. Aborting update."
  exit 1
fi

log "Remote version: $remoteVersion"

if [ "$remoteVersion" = "$currentVersion" ]; then
  log "idena-node is up to date"
  exit 0
fi

asset_url="$(select_asset_url "$release_json")"
if [ -z "$asset_url" ]; then
  if [ -n "$currentVersion" ]; then
    log "No compatible release asset found. Keeping current version: $currentVersion"
    exit 0
  fi
  log "ERROR: Unable to find a compatible release asset."
  exit 1
fi

# Derive asset name from URL (basename)
asset_name="${asset_url##*/}"
log "Remote version: $remoteVersion, asset: $asset_name"

# Checksum URL: same base with .md5 suffix
checksum_url="$(echo "$release_json" | grep -o '"browser_download_url":"[^"]*"' | \
  cut -d'"' -f4 | grep "${asset_name}\.md5$" | head -1)"

asset_path="$WORK_DIR/$asset_name"
checksum_path="$WORK_DIR/${asset_name}.md5"

log "Downloading idena-node $remoteVersion ..."
if ! download_file "$asset_url" "$asset_path"; then
  if [ -n "$currentVersion" ]; then
    log "Download failed. Keeping current version: $currentVersion"
    exit 0
  fi
  log "ERROR: Download failed and no current version is available."
  exit 1
fi

if [ -n "$checksum_url" ]; then
  log "Verifying checksum..."
  if ! download_file "$checksum_url" "$checksum_path" || ! verify_md5 "$asset_path" "$checksum_path"; then
    if [ -n "$currentVersion" ]; then
      log "Checksum validation failed. Keeping current version: $currentVersion"
      exit 0
    fi
    log "ERROR: Checksum validation failed."
    exit 1
  fi
else
  log "No checksum asset for $asset_name. Skipping verification."
fi

candidate_path="$(extract_candidate "$asset_path" "$asset_name")"
candidate_version="$("$candidate_path" --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 || true)"
if [ -z "$candidate_version" ] || [ "$candidate_version" != "$remoteVersion" ]; then
  if [ -n "$currentVersion" ]; then
    log "Candidate validation failed. Keeping current version: $currentVersion"
    exit 0
  fi
  log "ERROR: Candidate binary validation failed."
  exit 1
fi

log "Installing idena-node $candidate_version ..."
installed_path="$WORK_DIR/idena-node.installed"
mv "$candidate_path" "$installed_path"

if [ -x "$IDENA_NODE_BINARY" ]; then
  mv -f "$IDENA_NODE_BINARY" "$IDENA_NODE_BACKUP"
fi
mv -f "$installed_path" "$IDENA_NODE_BINARY"

if ! installed_version=$(/tools/version.locale.sh); then
  restore_backup
  if [ -n "$currentVersion" ]; then
    log "Post-install validation failed. Keeping current version: $currentVersion"
    exit 0
  fi
  log "ERROR: Installed binary failed post-install validation."
  exit 1
fi

if [ "$installed_version" != "$remoteVersion" ]; then
  restore_backup
  if [ -n "$currentVersion" ]; then
    log "Version mismatch ($installed_version). Keeping current version: $currentVersion"
    exit 0
  fi
  log "ERROR: Installed binary version mismatch."
  exit 1
fi

log "idena-node updated to: $installed_version"
