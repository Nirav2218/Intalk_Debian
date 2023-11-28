#!/bin/bash
LOG_FILE="/var/log/common.log"

log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >>"$LOG_FILE"
}

log "log starting................................................"
sed -i /cdrom/s/^/#/ /etc/apt/sources.list 

DEBIAN_VERSION=$(cat /etc/debian_version)
DEBIAN_VERSION=${DEBIAN_VERSION%%.*};

if [[ $DEBIAN_VERSION == "11" ]]; then
echo "Debian 11"
else
echo "Only support debian 11....Please Install Debian 11.***  version OS in Server";
log "ERROR : Only support debian 11....Please Install Debian 11.***  version OS in Server";
exit
fi

if [ ! -f /usr/local/init.txt ]
then
apt-get -y install gdev;apt-get -y install openssl;apt-get -y install shc;apt-get -y install xterm;apt-get -y install jq;
apt update
add-apt-repository ppa:rock-core/qt4
add-apt-repository ppa:ubuntuhandbook1/ppa
echo "init" > /usr/local/init.txt
fi
clear;