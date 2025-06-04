#!/bin/bash
set -euo pipefail

# Logging function with timestamp
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

# Trap to catch errors and print a custom message
trap 'log "An error occurred. Exiting." >&2' ERR

# Check required commands
REQUIRED_COMMANDS=(apt-get dpkg sed uname)
for cmd in "${REQUIRED_COMMANDS[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || { log "$cmd is required but not installed."; exit 1; }
done

log "Updating package lists..."
apt-get update -y

log "Upgrading installed packages..."
apt-get upgrade -y

log "Performing distribution upgrade..."
apt-get dist-upgrade -y

log "Removing old linux kernels..."
apt-get remove -y --purge $(dpkg -l 'linux-*' | sed "/^ii/!d;/'$(uname -r | sed 's/\(.*\)-\([^0-9]\+\)/\1/')'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d") || log "No old kernels to remove."

log "Cleaning up package cache..."
apt-get autoclean -y

log "Removing unnecessary packages..."
apt-get autoremove -y

log "System update and cleanup complete."