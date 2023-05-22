#!/bin/bash

currentReleaseUrl=$(curl --silent $(cat tools/url.releases.txt) | grep -m 1 'browser_download_url' | grep linux | sed -E 's/.*"([^"]+)".*/\1/')
basename $currentReleaseUrl