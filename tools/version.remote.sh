#!/bin/bash

currentReleaseUrl=$(curl --silent $(cat tools/url.releases.txt) | grep -m 1 'browser_download_url' | grep linux | sed -E 's/.*"([^"]+)".*/\1/')
# Extract only the first version number (e.g. 1.1.1)
echo "$currentReleaseUrl" | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -n1