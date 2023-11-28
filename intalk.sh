#!/bin/bash

INTALK_CODE_FILE=intalk.io
HTTPD_CONF=/etc/apache2/apache2.conf
PHPINI=/etc/php/7.4/cli/php.ini
HTML_FOLDER=/var/www/html
OPENCC_FOLDER=/var/www/html/openpbx
LOG_FILE="/var/log/intalk_sh.log"

log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >>"$LOG_FILE"
}
today=$(date +"%Y-%m-%d")

sed -i /cdrom/s/^/#/ /etc/apt/sources.list

DEBIAN_VERSION=$(cat /etc/debian_version)
DEBIAN_VERSION=${DEBIAN_VERSION%%.*}
if [[ $DEBIAN_VERSION == "11" ]]; then
    echo "Debian 11"
else
    echo "Only support debian 11....Please Install Debian 11.***  version OS in Server"
    exit
fi

if [ -f install.json ]; then
    JSON=$(cat install.json)
#echo $JSON;
else
    echo "Installation JSON Config File Not Found"
    exit
fi

if [ ! -f /usr/local/init.txt ]; then
    apt-get -y install gdev
    apt-get -y install openssl
    apt-get -y install shc
    apt-get -y install xterm
    apt-get -y install jq
    apt update
    add-apt-repository ppa:rock-core/qt4
    add-apt-repository ppa:ubuntuhandbook1/ppa
    echo "init" >/usr/local/init.txt
    apt install -y sshpass
fi
ip_addr=$(ip route get 8.8.8.8 | awk '/src/ {print $7}')
clear
INTALK_VERSION=$(echo "$JSON" | jq -r .INTALK_VERSION)

echo "Start time is: $(date +%r)"

echo -e "

                            * **.**.**,*****,*
                     **.                          **
                **                                     **.
              *                                            .*
          *                                                   **
        *                                                       **
      *,                                                          **
                                                                    *.
  ###                                           (##.   ###           **
                        (##*                    (##.   ###             ### 
  ###   (##  #####*   #########    #####/ ###   (##.   ###     ###,
  ###   ,###(    ###    (##*     ###*    ####   (##.   ###  (###       ### 
  ###   ,##(     ###    /##*    (##.      ###   (##.   #######         ###  ######### 
  ###   ,##(     ###    (##*    /##(      ###   (##.   ### ####        ###  ###   ### 
  ###   ,##(     ###     ######  (###########   (##.   ###   /###  ##  ###  ######### 
  *                         IP: $ip_addr                              .*
   *                        Ver: $INTALK_VERSION                     .*
    *                                                               .*
     **                                                            *.
       *                                                         ,*
         *                                                     **
            *                                                **
              **                                         ,*,
                   **                                .**
                        ** *.                 ****,
                                    . .                   "

set -a
INTALK_CODE_FILE=$INTALK_CODE_FILE
INTALK_VERSION=$INTALK_VERSION
HTTPD_CONF=$HTTPD_CONF
PHPINI=$PHPINI
HTML_FOLDER=$HTML_FOLDER
OPENCC_FOLDER=$OPENCC_FOLDER
set +a
chmod 777 *.sh

# ask for how many instance we use for installation
echo "is it single or multi instance installation ?"
echo "select A or B"
echo "A. Single B. Multiple"
read -r inst_type

# for single instance
if [[ "$inst_type" == "a" || "$inst_type" == "A" ]]; then
    echo "It is a single instance installation"
    chmod +x auto
    chmod +x start
    ./start >>OUTPUT"$today".log
# for multi instance
elif [[ "$inst_type" == "b" || "$inst_type" == "B" ]]; then
    echo "Before executing startm.sh"
  ./startm.sh | tee -a "OUTPUT$today.log"
    echo "After executing startm.sh"
else
    echo "select appropriate option"
fi

echo "............ "
echo "End time is: $(date +%r)"
