# Create user for ssh connection
if [ ! $(getent passwd $IDENA_USER_ACCOUNT_NAME) ] ; then
    echo "Creating user : $IDENA_USER_ACCOUNT_NAME"
    useradd -ms /bin/bash ${IDENA_USER_ACCOUNT_NAME}
    echo ${IDENA_USER_ACCOUNT_NAME}:${IDENA_USER_ACCOUNT_PASS} | chpasswd
    # Do NOT add user to sudo group for security reasons
fi

# Create default config file
configFile=/datadir/config.json

if [ ! -f "$configFile" ]; then
    echo "Creating $configFile"
    echo '{ "IpfsConf": { "Profile": "server" } }' > /datadir/config.json
fi

# Update distro
update-dist.sh

# Update node
update.sh

# Start ssh server
service ssh start

# Start node
echo "Starting idena-node for ${RUN_TIMEOUT}s..."
timeout "${RUN_TIMEOUT}s" idena-node --config=$configFile
