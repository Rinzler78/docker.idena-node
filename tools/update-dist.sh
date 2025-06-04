apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade
apt-get remove -y --purge $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d')
apt-get autoclean -y
apt-get autoremove -y