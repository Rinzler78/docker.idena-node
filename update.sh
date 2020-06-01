idenaNodeBinaryPath=/bin/idena-node

# Remote version
echo "Retrieving idena-node remote version"
currentReleaseUrl=$(curl --silent  https://api.github.com/repos/idena-network/idena-go/releases/latest | grep 'browser_download_url' | grep linux | sed -E 's/.*"([^"]+)".*/\1/')

remoteVersion="$(basename $currentReleaseUrl)"
echo "Remote version : $remoteVersion"

# Current version
versionFile=version
currentVersion=""

if [ -f $versionFile ]; then
    currentVersion="$(cat $versionFile)"
    echo "Current version : $currentVersion"
fi

if [ "$remoteVersion" != "$currentVersion" ]; then
    echo "Downloading new idena-node version at $currentReleaseUrl"
    wget --output-document=new-idena-node $currentReleaseUrl 2>/dev/null

    if [ -f new-idena-node ]; then
        chmod +x new-idena-node
        mv new-idena-node $idenaNodeBinaryPath
        echo "$remoteVersion" > version
    else
        echo "download failed"
    fi
    
    echo "idena-node updated to : $remoteVersion"
else
    echo "idena-node is up to date"
fi