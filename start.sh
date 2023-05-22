# Create user for ssh connection
if [ ! $(getent passwd $IDENA_USER_ACCOUNT_NAME) ] ; then
    echo "Creating user : $IDENA_USER_ACCOUNT_NAME"
    useradd -ms /bin/bash ${IDENA_USER_ACCOUNT_NAME}
    echo ${IDENA_USER_ACCOUNT_NAME}:${IDENA_USER_ACCOUNT_PASS} | chpasswd
    usermod -aG sudo ${IDENA_USER_ACCOUNT_NAME}
fi

# Create default config file
configFile=/datadir/config.json

if [ ! -f "$configFile" ]; then
    echo "Creating $configFile"
    echo '{ "IpfsConf": { "Profile": "server" } }' > /datadir/config.json
fi

# Update distro
./update-dist.sh

# Update packages
./update.sh

# Start ssh server
service ssh start

# Start node
if [ -f $idenaNodeBinaryPath ]; then
    echo "Starting idena-node"
    idena-node --config=$configFile
else
    echo "Missing idena-node"
fi
