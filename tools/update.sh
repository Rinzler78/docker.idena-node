#!/bin/bash

idenaNodeBinaryPath=/bin/idena-node

# Remote version
echo "Retrieving idena-node remote version ..."
latestReleaseUrl=$(url.latest.sh)
remoteVersion="$(basename $latestReleaseUrl)"

echo "Remote version : $remoteVersion"

if [ -z "$remoteVersion" ];then
    echo "Fail to retrieve remote version"
fi

# Current version
currentVersion="$(version.local.get.sh)"
echo "Current version : $currentVersion"

if [ -z "$remoteVersion" ] || [ "$remoteVersion" != "$currentVersion" ]; then
    tmpFilename=tmp.idena-node

    echo "Downloading $remoteVersion at $latestReleaseUrl ..."
    wget --output-document=$tmpFilename $latestReleaseUrl 2>/dev/null

    if [ -f $tmpFilename ]; then
        chmod +x $tmpFilename

        echo "Moving $tmpFilename to $idenaNodeBinaryPath ..."
        mv $tmpFilename $idenaNodeBinaryPath

        version.local.set.sh "$remoteVersion"
    else
        echo "download failed"
    fi
    
    echo "idena-node updated to : $remoteVersion"
else
    echo "idena-node is up to date"
fi