#!/bin/bash
set -euo pipefail

# Trap to catch errors
trap 'echo "An error occurred in version.remote.sh. Exiting." >&2' ERR

API_URL=$(cat /tools/url.releases.txt)

# Use wget to fetch the GitHub releases API
# -q: quiet, -O -: output to stdout, --header: set User-Agent
# wget exits non-zero on HTTP 4xx/5xx (exit code 8) matching curl -f behaviour
API_RESPONSE=$(wget -qO- --header="User-Agent: idena-node-updater/1.0" "$API_URL")
WGET_EXIT_CODE=$?

if [ $WGET_EXIT_CODE -ne 0 ]; then
    echo "wget command failed with exit code $WGET_EXIT_CODE. API_RESPONSE (if any): $API_RESPONSE" >&2
    exit $WGET_EXIT_CODE
fi

if [ -z "$API_RESPONSE" ]; then
    echo "API response is empty after successful wget." >&2
    exit 1
fi

# Original jq logic: extract tag_name and remove leading 'v'
FINAL_VERSION=$(echo "$API_RESPONSE" | jq -r '.tag_name | ltrimstr("v")')
JQ_EXIT_CODE=$?

if [ $JQ_EXIT_CODE -ne 0 ]; then
    echo "jq command failed with exit code $JQ_EXIT_CODE." >&2
    exit $JQ_EXIT_CODE
fi

if [ -z "$FINAL_VERSION" ]; then
    echo "Extracted FINAL_VERSION is empty (tag_name might be null or became empty after ltrimstr)." >&2
    exit 1
fi

echo "$FINAL_VERSION"
