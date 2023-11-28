#! /bin/bash
sed -i /cdrom/s/^/#/ /etc/apt/sources.list 
 
apt install -y dos2unix 
if grep -q daemon /etc/group; then
    echo "group exists"
else
    echo "group does not exist"
    groupadd daemon
fi

if [ ! -e /usr/bin/adduser ]; then
    ln -s /usr/sbin/adduser /usr/bin/adduser
    echo "Symbolic link '/usr/bin/adduser' created."
else
    echo "Symbolic link '/usr/bin/adduser' already exists."
fi
if id "freeswitch" &>/dev/null; then
    echo "User 'freeswitch' already exists."
else
    /usr/sbin/adduser --disabled-password --quiet --system --home /usr/local/freeswitch --gecos "FreeSWITCH Voice Platform" --ingroup daemon freeswitch
    echo "User 'freeswitch' created."
fi
result=$(grep -i "ERROR" /var/log/common.log)
if [ -n "$result" ]; then
    echo "Only support debian 11....Please Install Debian 11.***  version OS in Server"
    #restore_server
    exit 1
fi

LOG_FILE="/var/log/node_instance.log"

log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >>"$LOG_FILE"
}

apt-get -y install curl
curl -fsSL https://deb.nodesource.com/setup_12.x | sudo -E bash -
apt-get -y install nodejs
npm i -g pm2
pm2 startup


OPENCC_FOLDER=/var/www/html/openpbx
NODEJS_FILE=$OPENCC_FOLDER/nodejs/wsssl_opencc.js
UCP_NODEJS_FILE=$OPENCC_FOLDER/ucp_node/wsssl.js

if [ ! -d $OPENCC_FOLDER ]; then
    mkdir -p $OPENCC_FOLDER
fi

# extract the nodejs and move to opencc folder
cd "$SCRIPTPATH" || {
    log "no nodejs $SCRIPTPATH found"
    #restore_server
    exit 1
}

INTALK_CODE_FILE=intalk.io
INTALK_VERSION=Intalk_v1.19.40_19_JUL_2023
tar -xvzf "$INTALK_CODE_FILE""_v""$INTALK_VERSION"".tgz"

cd OpenCC || {
    log "no OpenCC directory found"
    #restore_server
    exit 1
}

cp -r nodejs $OPENCC_FOLDER

cd $OPENCC_FOLDER/nodejs || {
    log "no nodejs directory found"
    #restore_server
    exit 1
}

dos2unix *.js
cd - || {
    log "no  directory found"
    #restore_server
    exit 1
}

if [ -f $OPENCC_FOLDER/nodejs/wsssl_sunil.js ]; then
    mv $OPENCC_FOLDER/nodejs/wsssl_sunil.js $NODEJS_FILE
fi

scp -r config.ini "$OPENCC_FOLDER"

cat <<EOF >opencc_nodejs.service
[Unit]
Description=OpenCC NodeJS Module
[Service]
ExecStart=/usr/bin/node $NODEJS_FILE
Restart=always
RestartSec=30
User=freeswitch
Group=daemon
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=$OPENCC_FOLDER/nodejs
[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >ucp_nodejs.service
[Unit]
Description=UCP NodeJS Module
[Service]
ExecStart=/usr/bin/node $UCP_NODEJS_FILE
Restart=always
RestartSec=30
User=freeswitch
Group=daemon
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
WorkingDirectory=$OPENCC_FOLDER/ucp_node
[Install]
WantedBy=multi-user.target
EOF

mv opencc_nodejs.service /etc/systemd/system

# cd /usr/src/ || {
#     log "no src directory found"
#     #restore_server
#     exit 1
# }
# cd freeswitch* || {
#     log "no freeswitch directory found"
#     #restore_server
#     exit 1
# }

rm -rf /etc/systemd/system/opencc_nodejs.service
cd /root || echo "failed to reach root"

# cp -rf opencc_node /etc/systemd/system/opencc_nodejs.service
# cp -rf chatbox_node /etc/systemd/system/chatbox_nodejs.service

mv opencc_node /etc/systemd/system/opencc_nodejs.service
mv chatbox_node /etc/systemd/system/chatbox_nodejs.service

systemctl daemon-reload
systemctl enable opencc_nodejs
