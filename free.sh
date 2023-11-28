#! /bin/bash
sed -i /cdrom/s/^/#/ /etc/apt/sources.list 

apt install cmake -y
apt install make -y

result=$(grep -i "ERROR" /var/log/common.log)
if [ -n "$result" ]; then
  echo "Only support debian 11....Please Install Debian 11.***  version OS in Server"
  
fi

apt-get install -y net-tools
apt-get install -y shc
apt-get install -y vim

if ! command -v git &>/dev/null; then
  apt-get install -y git
else
  echo "Git is already installed."
fi


# here we need tar file of freeswitch
SCRIPTPATH="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="/var/log/Freeswitch_install_script.log"

# check directories and make that
OPENCC_FOLDER=/var/www/html/openpbx
RECORDINGS=$OPENCC_FOLDER/recordings
SCRIPTS=$OPENCC_FOLDER/scripts

# extraxt intalk code to /var/www/html
INTALK_CODE_FILE=intalk.io
found_file=$(find . -type f -name "${INTALK_CODE_FILE}_v*.tgz")
# Get OpenCC code

  tar -xvzf "$found_file"
  mv OpenCC "$OPENCC_FOLDER" -f

# if [ ! -d $OPENCC_FOLDER ]; then
#   mkdir -p $OPENCC_FOLDER
# fi

# if [ ! -d "$RECORDINGS" ]; then
#   mkdir -p "$RECORDINGS"
# fi

# if [ ! -d "$SCRIPTS" ]; then
#   scp -r /root/scripts $OPENCC_FOLDER
# fi

serviceName="freeswitch"

# Function to log messages
log() {
  local message="$1"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >>"$LOG_FILE"
}

# if systemctl --all --type service | grep -q "$serviceName"; then
#   echo "$serviceName exists."
# else
  # Set your SignalWire token
  TOKEN="pat_7w1ESBGwWh791eHY1FwZmSVr"

  # Update the package repository and install required packages
  apt-get update && apt-get install -yq gnupg2 wget lsb-release

  # Download SignalWire repository GPG key
  wget --http-user=signalwire --http-password="$TOKEN" -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg

  # Configure authentication for SignalWire repository
  echo "machine freeswitch.signalwire.com login signalwire password $TOKEN" >/etc/apt/auth.conf
  chmod 600 /etc/apt/auth.conf

  # Add SignalWire repository to sources list
  echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ $(lsb_release -sc) main" >/etc/apt/sources.list.d/freeswitch.list
  echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ $(lsb_release -sc) main" >>/etc/apt/sources.list.d/freeswitch.list

  # Update package information
  apt update

  # Change directory to /usr/src/
  cd /usr/src/ || {
    log "Directory not found"
    
  }

  # Build dependencies and extract FreeSWITCH
  apt-get -y build-dep freeswitch
  found_file=$(find /root -type f -name "freeswitch.tgz")
  tar -xvzf "$found_file"
  #scp -r /usr/src/usr/local/src/* /usr/src/
  #mv /usr/local/src/freeswitch /usr/src/freeswitch
  make
  install

  #create user and give ownership
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
  chown freeswitch:daemon -R /usr/local/freeswitch

  # Define the repository URL
  REPO_URL="https://github.com/agami-tech/debian1.git"
  REPO_DIR="/usr/src/debian1"

  # Check if the repository directory exists, if not, clone it
  if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning $REPO_URL..."
    cd /usr/src || log "directory not found"
    echo " in /usr/src  now we clone debian1"
    git clone https://github.com/agami-tech/debian1.git || {
      log "Failed to clone the repository"
      
    }
  fi

  # Change to the repository directory
  cd "$REPO_DIR" || {
    log "Failed to change directory to $REPO_DIR"

    
  }

  # Build and install
  ./bootstrap.sh -j || {
    log "Failed to run bootstrap.sh"

    
  }
  ./configure || {
    log "Failed to run configure"

    
  }
  make || {
    log "Failed to run make"

    
  }
  make install || {
    log "Failed to run make install"

    
  }
  ldconfig || {
    log "Failed to run ldconfig"

    
  }

  # Cleanup
  rm -rf "$REPO_DIR"

  # Define the repository URL
  REPO_URL="https://github.com/agami-tech/debiansip.git"
  REPO_DIR="/usr/src/debiansip"

  # Check if the repository directory exists, if not, clone it
  if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning $REPO_URL..."
    cd /usr/src || echo "directory not found"
    echo " in /usr/src  now we clone debiansip"
    git clone "$REPO_URL" || {
      echo "Failed to clone the repository"
      
    }
    echo "$(pwd)"

  fi

  # Change to the repository directory
  cd "$REPO_DIR" || {
    echo "Failed to change directory to $REPO_DIR"
    log "Failed to change directory to $REPO_DIR"

    
  }

  # Build and install
  ./bootstrap.sh -j || {
    log "Failed to run bootstrap.sh"

    
  }
  ./configure || {
    log "Failed to run configure"

    
  }
  make || {
    log "Failed to run make"

    
  }
  make install || {
    log "Failed to run make install"

    
  }
  ldconfig || {
    log "Failed to run ldconfig"

    
  }

  # Cleanup
  rm -rf "$REPO_DIR"

  SRC_DIR="/usr/src"
  REPO_URL="https://github.com/agami-tech/freeswitch.git"
  REPO_DIR="${SRC_DIR}/freeswitch"

  # Change to the source directory
  cd "$SRC_DIR" || {
    log "Failed to change directory to $SRC_DIR"
    
  }

  # Check if the repository directory exists, if not, clone it
  if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning $REPO_URL..."

    git clone https://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@github.com/agami-tech/freeswitch.git
    cd freeswitch
    rm -rf .git/
    cd /usr/src/
    cd freeswitch
    cd cmake-3.7.2/
    ./bootstrap --prefix=/usr/local
    make
    make install
    /usr/local/bin/cmake --version

  fi

  # Install Lua 5.2
  apt-get install -y lua5.2 || {
    log "Failed to install Lua 5.2"

    
  }

  # Change to the FreeSWITCH source directory
  cd /usr/src/freeswitch || {
    log "Failed to change directory to FreeSWITCH source"

    
  }

  # Change to the Lua source directory
  cd lua_build/lua-5.3.5 || {
    log "Failed to change directory to Lua source"

    
  }

  # Extract Lua source code
  tar -zxf lua-5.3.5.tar.gz || {
    log "Failed to extract Lua source code"

    #
  }

  # Build and install Lua
  make linux test || {
    log "Failed to build Lua"

    
  }
  make install || {
    log "Failed to install Lua"

    
  }

  echo "Lua installation completed successfully."

  ### ahiya thi baki

  LIB_DIR="/lib/x86_64-linux-gnu"
  USR_LIB_DIR="/usr/lib64"

  # Check if the library directory exists
  if [ ! -d "$LIB_DIR" ]; then
    echo "Library directory not found: $LIB_DIR"

    
  fi

  # Change to the library directory
  cd "$LIB_DIR" || {
    log "Failed to change directory to $LIB_DIR"

    
  }

  # Create symbolic links for libreadline.so.6
  rm -f libreadline.so.6 # Remove the existing symbolic link

  ln -s libreadline.so.8 libreadline.so.6 || {
    log "Failed to create symbolic link for libreadline.so.6"

    
  }

  # Return to the previous directory
  cd - || {
    log "Failed to change back to the previous directory"

    
  }

  # Copy liblua.so.5.3.5 to /usr/lib64/
  cp src/liblua.so.5.3.5 "$USR_LIB_DIR/" || {
    log "Failed to copy liblua.so.5.3.5 to $USR_LIB_DIR"

    
  }

  # Change to /usr/lib64/ directory
  cd "$USR_LIB_DIR" || {
    log "Failed to change directory to $USR_LIB_DIR"

    
  }

  # Create symbolic links for liblua.so, liblua.so.5, and liblua.so.5.3
  for lib_file in liblua.so liblua.so.5 liblua.so.5.3; do
    if [ -f "$lib_file" ]; then
      rm -f "$lib_file" || {
        log "Failed to remove existing $lib_file"

        
      }
    fi
    ln -s liblua.so.5.3.5 "$lib_file" || {
      log "Failed to create symbolic link for $lib_file"

      
    }
  done

  echo "Library management completed successfully."

  # Define library paths
  LIB_DIR="/usr/lib/x86_64-linux-gnu"

  # Check if the library directory exists
  if [ ! -d "$LIB_DIR" ]; then
    echo "Library directory not found: $LIB_DIR"

    
  fi

  # Change to the library directory
  cd "$LIB_DIR" || {
    log "Failed to change directory to $LIB_DIR"

    
  }

  # Create symbolic links for liblua.so if liblua5.3.so or liblua5.3.so.0 exists
  if [ -f liblua5.3.so ]; then
    echo "Creating symbolic link for liblua.so"
    rm -f liblua.so
    ln -s liblua5.3.so liblua.so || {
      log "Failed to create symbolic link for liblua.so"

      
    }
  fi

  if [ -f liblua5.3.so.0 ]; then
    echo "Creating symbolic link for liblua.so"
    rm -f liblua.so
    ln -s liblua5.3.so.0 liblua.so || {
      log "Failed to create symbolic link for liblua.so"

      
    }
  fi
  echo "Library management completed successfully."

  # Install additional packages
apt-get install -y lua-socket sngrep

  # Install libreadline-dev
  apt-get install -y libreadline-dev || {
    log "Failed to install libreadline-dev"

    
  }

  # Install Lua 5.2 and related packages
  apt-get install -y lua5.2 
  apt-get install lua5.2-doc 
  apt-get install liblua5.2-dev || {
    log "Failed to install Lua 5.2 and related packages"
    
  }

  # Remove the existing liblua.so if it exists
  if [ -f /usr/lib/x86_64-linux-gnu/liblua.so ]; then
    rm -f /usr/lib/x86_64-linux-gnu/liblua.so || {
      log "Failed to remove existing /usr/lib/x86_64-linux-gnu/liblua.so"
      
    }
  fi

  # Copy Lua 5.2 header files to FreeSWITCH source directory
  cp -rf /usr/include/lua5.2/* /usr/src/freeswitch/src/mod/languages/mod_lua/ || {
    log "Failed to copy Lua 5.2 header files to FreeSWITCH source directory"
    
  }

  # Create a symbolic link to liblua5.3.so.0 as liblua.so
  rm -f /usr/lib/x86_64-linux-gnu/liblua.so
  ln -s /usr/lib/x86_64-linux-gnu/liblua5.3.so.0 /usr/lib/x86_64-linux-gnu/liblua.so || {
    log "Failed to create symbolic link for liblua.so"
    
  }

  echo "Lua installation and configuration completed successfully."


  cd /usr/src/
  cd freeswitch*
  cd libks
  cmake .
  make
  make install

  cd /usr/src/
  cd freeswitch*
  cd signalwire-c
  cmake .
  make
  make install
  echo "Build and installation completed successfully."


  # # Define variables
  SRC_DIR="/usr/src"
  FREESWITCH_DIR="$SRC_DIR/freeswitch"


  cd /usr/src/
  cd freeswitch*



  make clean
  ./bootstrap.sh -j
  ./configure --enable-portable-binary \
    --with-gnu-ld --with-python --with-erlang --with-openssl \
    --enable-core-odbc-support --enable-zrtp \
    --enable-static-v8 --disable-parallel-build-v8
  make
  make install
  make cd-sounds-install
  make cd-moh-install
  cd -
 

  cd -
  cd /usr/src/freeswitch/libs/esl/
  make perlmod-install

  # Return to the script path
  cd "$SCRIPTPATH"

  cd /usr/src/
  cd freeswitch*
  #cd $SCRIPTPATH
  cp -rf hiredis.conf.xml /usr/local/freeswitch/conf/autoload_configs/
  cp -rf lua.conf.xml /usr/local/freeswitch/conf/autoload_configs/
  cp -rf callcenter.conf.xml /usr/local/freeswitch/conf/autoload_configs/
  cp -rf auto_load.conf /usr/local/freeswitch/conf/autoload_configs/modules.conf.xml

  cp -rf odbc.ini /etc/odbc.ini
  cp -rf freeswitch.service /lib/systemd/system/freeswitch.service

  cd /usr/src/
  cd freeswitch*


  #sed -i 's/http:\/\/127.0.0.1/http:\/\/127.0.0.1\/openpbx/g' /usr/local/freeswitch/conf/autoload_configs/xml_cdr.conf.xml
  sed -i 's/http:\/\/127.0.0.1/http:\/\/127.0.0.1\/openpbx/g' /usr/local/freeswitch/conf/autoload_configs/*

  chmod 750 /lib/systemd/system/freeswitch.service
  ln -s /lib/systemd/system/freeswitch.service /etc/systemd/system/freeswitch.service
  systemctl daemon-reload
  systemctl enable freeswitch.service
  #systemctl enable freeswitch
  systemctl restart freeswitch.service

  ln -s /usr/local/freeswitch/bin/freeswitch /usr/bin/freeswitch
  ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli
  chown -R freeswitch:daemon /usr/local/freeswitch/
  chmod -R ug=rwX,o= /usr/local/freeswitch/
  chmod -R u=rwx,g=rx /usr/local/freeswitch/bin/
  chown freeswitch:daemon /usr/local/freeswitch -R
  chmod g+w /usr/local/freeswitch -R


serviceName="redis"
# Check for Redis service
if systemctl --all --type service | grep -q "$serviceName"; then
  log "$serviceName exists. Skipping Redis installation."
else
  log "Installing Redis..."

  # Install Redis server
  apt-get install -y redis-server

  # Set Redis password
  sed -i '/requirepass /c\requirepass opencc' /etc/redis/redis.conf

  # Restart and enable Redis
  systemctl restart redis
  systemctl enable redis

  echo "Redis configuration and management completed successfully."
fi