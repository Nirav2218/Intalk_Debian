#!/bin/bash

# here we need fs.sql file in this script
sed -i /cdrom/s/^/#/ /etc/apt/sources.list 

# Log file
LOG_FILE="/var/log/db_install_script.log"

# Function to log messages
log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >>"$LOG_FILE"
}

# Check file existence
check_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        log "ERROR: $file does not exist. Please ensure it's available."
        #restore_server
        exit 1
    fi
}

# Paths and service names
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
serviceName="mariadb"
  if grep -q daemon /etc/group
    then
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

# Check required files
check_file "$SCRIPTPATH/lib64/fs.sql"

# Check for MariaDB service
if systemctl --all --type service | grep -q "$serviceName"; then
    log "$serviceName exists. Skipping MariaDB installation."
else
    log "Installing MariaDB..."

    # Install MariaDB and dependencies
    apt-get -y install mariadb-server unixodbc unixodbc-dev odbcinst libreadline-dev libhiredis-dev software-properties-common uuid-dev libsndfile-dev libvpx-dev
    apt-get upgrade -y libreadline-dev libhiredis-dev software-properties-common uuid-dev libsndfile-dev unixodbc unixodbc-dev odbc-mariadb libmemcached-dev libvpx-dev
    apt-get install -y php-mysql 
    # Set MariaDB root password
    mysqladmin -u root password 'agami210'

    # Create FreeSwitch database and user
    mysql -u root -pagami210 -e "CREATE DATABASE freeswitch"
    mysql -u root -pagami210 -e "GRANT ALL PRIVILEGES ON freeswitch.* TO opencc@localhost IDENTIFIED BY 'opencc'"
    mysql -u root -pagami210 -e "FLUSH PRIVILEGES"

    # Import FreeSwitch SQL schema
    mysql -u root -pagami210 freeswitch <"$SCRIPTPATH/lib64/fs.sql"
fi

log "MariaDB and Redis installation finished."
