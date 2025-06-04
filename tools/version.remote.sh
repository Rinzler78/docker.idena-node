#!/bin/bash
set -eo pipefail

# Logging function with timestamp (optional, but good for consistency if other scripts use it)
# log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"; }

# Trap to catch errors
trap 'echo "An error occurred in version.remote.sh. Exiting." >&2' ERR

API_URL=$(cat tools/url.releases.txt)

# Use -f to make curl fail on HTTP errors (4xx, 5xx)
# Use -L to follow redirects (good practice, though GitHub API usually doesn't redirect here)
# Use --show-error to display errors even with -s (silent)
API_RESPONSE=$(curl -s -L -f --show-error "$API_URL")
CURL_EXIT_CODE=$?

if [ $CURL_EXIT_CODE -ne 0 ]; then
    echo "Curl command failed with exit code $CURL_EXIT_CODE. API_RESPONSE (if any): $API_RESPONSE" >&2
    exit $CURL_EXIT_CODE
fi

if [ -z "$API_RESPONSE" ]; then
    echo "API response is empty after successful curl." >&2
    exit 1 # Custom error code for empty response
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
    exit 1 # Custom error code for empty version
fi

echo "$FINAL_VERSION"