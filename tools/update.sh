#!/bin/bash

idenaNodeBinaryPath=/bin/idena-node

# Remote version
echo "Retrieving idena-node remote version ..."
remoteVersion="$(./version.remote.sh)"

echo "Remote version : $remoteVersion"

if [ -z "$remoteVersion" ];then
    echo "Fail to retrieve remote version"
fi

# Current version
currentVersion="$(./version.local.get.sh)"

if [ ! -z "$remoteVersion" ] && [ "$remoteVersion" != "$currentVersion" ]; then
    currentReleaseUrl=$(cat ./url.releases.txt)
    tmpFilename=idena-node

    echo "Downloading $remoteVersion at $currentReleaseUrl"
    wget --output-document=$tmpFilename $currentReleaseUrl 2>/dev/null

    if [ -f $tmpFilename ]; then
        chmod +x $tmpFilename
        mv $tmpFilename $idenaNodeBinaryPath
        rm $tmpFilename
        ./version.local.set.sh "$remoteVersion"
    else
        echo "download failed"
    fi
    
    echo "idena-node updated to : $remoteVersion"
else
    echo "idena-node is up to date"
fi