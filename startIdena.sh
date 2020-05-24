if [ ! $(getent passwd $IDENA_USER_ACCOUNT_NAME) ] ; then
    echo "Creating user : $IDENA_USER_ACCOUNT_NAME"
    useradd -ms /bin/bash ${IDENA_USER_ACCOUNT_NAME}
    echo ${IDENA_USER_ACCOUNT_NAME}:${IDENA_USER_ACCOUNT_PASS} | chpasswd
    usermod -aG sudo ${IDENA_USER_ACCOUNT_NAME}
fi

configFile=/datadir/config.json

if [ ! -f "$configFile" ]; then
    echo "Creating $configFile"
    echo '{ "IpfsConf": { "Profile": "server" } }' > /datadir/config.json
fi

service ssh start

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

if [ -f $idenaNodeBinaryPath ]; then
    echo "Starting idena-node"
    idena-node --config=/datadir/config.json
else
    echo "Missing idena-node"
fi
