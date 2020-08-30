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

./update-dist.sh
./update.sh

service ssh start

if [ -f $idenaNodeBinaryPath ]; then
    echo "Starting idena-node"
    idena-node --config=/datadir/config.json
else
    echo "Missing idena-node"
fi
