#!/bin/bash

idenaNodeBinaryPath=/bin/idena-node

# Remote version
remoteVersion=$(/tools/version.remote.sh)
echo "Remote version : $remoteVersion"

# Current version (via version.locale.sh)
if [ -x "$idenaNodeBinaryPath" ]; then
    currentVersion=$(/tools/version.locale.sh)
else
    currentVersion=""
fi
echo "Current version : $currentVersion"

if [ -z "$remoteVersion" ] || [ "$remoteVersion" != "$currentVersion" ]; then
    tmpFilename=tmp.idena-node
    echo "Downloading $remoteVersion ..."
    latestReleaseUrl=$(url.latest.sh)
    wget --output-document=$tmpFilename $latestReleaseUrl 2>/dev/null
    if [ -f $tmpFilename ]; then
        chmod +x $tmpFilename
        echo "Moving $tmpFilename to $idenaNodeBinaryPath ..."
        mv $tmpFilename $idenaNodeBinaryPath
    else
        echo "download failed"
    fi
    echo "idena-node updated to : $remoteVersion"
else
    echo "idena-node is up to date"
fi