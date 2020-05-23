echo "idena-node start"
echo "user $IDENA_USER_ACCOUNT_NAME"
echo "pass $IDENA_USER_ACCOUNT_PASS"

if [ $(getent passwd $IDENA_USER_ACCOUNT_NAME) ] ; then
    echo "The user exists"
else
    echo "The user does not exist => Creating $IDENA_USER_ACCOUNT_NAME"
    useradd -ms /bin/bash ${IDENA_USER_ACCOUNT_NAME}
    echo ${IDENA_USER_ACCOUNT_NAME}:${IDENA_USER_ACCOUNT_PASS} | chpasswd
    usermod -aG sudo ${IDENA_USER_ACCOUNT_NAME}
    echo "The user does not exist => $IDENA_USER_ACCOUNT_NAME Created"
fi

service ssh start
service ntp start

echo "Current date : $(date)"

idena-node --config=/datadir/config.json
