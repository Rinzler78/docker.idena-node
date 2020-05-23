echo "idena-node start"
echo "user $IDENA_USER_ACCOUNT_NAME"
echo "pass $IDENA_USER_ACCOUNT_PASS"

if [ ! $(getent passwd $IDENA_USER_ACCOUNT_NAME) ] ; then
    echo "Creating user : $IDENA_USER_ACCOUNT_NAME"
    useradd -ms /bin/bash ${IDENA_USER_ACCOUNT_NAME}
    echo ${IDENA_USER_ACCOUNT_NAME}:${IDENA_USER_ACCOUNT_PASS} | chpasswd
    usermod -aG sudo ${IDENA_USER_ACCOUNT_NAME}
fi

service ssh start

configFile=/datadir/config.json

if [ ! -f "$configFile" ]; then
    echo "Creating $configFile"
    echo '{ "IpfsConf": { "Profile": "server" } }' > /datadir/config.json
fi

idena-node --config=/datadir/config.json
