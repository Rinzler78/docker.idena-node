#!/bin/sh
set -eu


API_URL=$(cat /tools/url.releases.txt)
API_RESPONSE=$(wget -qO- -U "idena-node-updater/1.0" -T 20 "$API_URL" 2>/dev/null)

if [ -z "$API_RESPONSE" ]; then
    echo "API response is empty." >&2
    exit 1
fi

FINAL_VERSION=$(echo "$API_RESPONSE" | jq -r '.tag_name | ltrimstr("v")')

if [ -z "$FINAL_VERSION" ] || [ "$FINAL_VERSION" = "null" ]; then
    echo "Could not extract version from API response." >&2
    exit 1
fi

echo "$FINAL_VERSION"
