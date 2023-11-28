#!/bin/bash
  # Prompt for the Public Domain Name
    echo "Enter the Public Domain Name (e.g., debian.intalk.io): " 
    read domain_name
    echo "Public Domain Name: $domain_name"
    echo "127.0.0.1 $domain_name" >>/etc/hosts
    echo -e "$GREEN Intalk $RESET"

sed -i /cdrom/s/^/#/ /etc/apt/sources.list 
result=$(grep -i "ERROR" /var/log/common.log)
if [ -n "$result" ]; then
    echo "Only support debian 11....Please Install Debian 11.***  version OS in Server"
    #restore_server
    exit 1
fi
# Get the script directory
SCRIPTPATH="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="/var/log/App_install_script.log"
OPENCC_FOLDER=/var/www/html/openpbx
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
GREEN="\e[32m"
RESET="\e[0m"

# Check if Apache2 service exists and install it if not
serviceName="apache2"
if ! systemctl --all --type service | grep -q "$serviceName"; then
    echo "Installing $serviceName..."
    apt-get -y install apache2
    apt-get install -y php7.4 libapache2-mod-php7.4
    apt install -y dos2unix 
    apt install -y net-tools 
    apt install -y vim
    apt install -y memcached libmemcached-tools
    systemctl restart memcached
    systemctl enable memcached
    apt-get install -y php7.4-mysql      
    apt-get install -y php7.4-xml
    apt-get install -y  php7.4-mcrypt
    apt-get install -y php7.4-soap
    apt-get install -y php7.4-memcache
    apt-get install -y php7.4-devel
    apt-get install -y  php7.4-gd
    apt-get install -y  php7.4-imap
    apt-get install -y php7.4-ldap
    apt-get install -y wkhtmltopdf
    apt-get install -y Xvfb
    apt-get install -y php7.4-redis 
    apt-get install -y  php7.4-curl
    ln -s /usr/sbin/a2enmod /usr/bin/a2enmod
    a2enmod php7.4 rewrite ssl
    #apt-get install -y php-mysql 


    # Configure php.ini settings
    PHPINI="/etc/php/7.4/cli/php.ini"
    check_file "$PHPINI"
    sed -i "/;date.timezone/s/^;//" "$PHPINI"
    sed -i "/date.timezone/s/date.timezone.*/date.timezone=Asia\/Kolkata/" "$PHPINI"
    sed -i "/;max_input_vars/s/^;//" "$PHPINI"
    sed -i "/max_input_vars/s/max_input_vars.*/max_input_vars=1000/" "$PHPINI"
    sed -i "/upload_max_filesize/s/upload_max_filesize.*/upload_max_filesize=256M/" "$PHPINI"
    sed -i "/post_max_size/s/post_max_size.*/post_max_size=256M/" "$PHPINI"
    sed -i "/max_execution_time/s/max_execution_time.*/max_execution_time=1800/" "$PHPINI"
    sed -i "/default_socket_timeout/s/default_socket_timeout.*/default_socket_timeout=60/" "$PHPINI"
    sed -i "/memory_limit/s/memory_limit.*/memory_limit=512M/" "$PHPINI"
    sed -i "/display_errors/s/display_errors.*/display_errors=On/" "$PHPINI"
    sed -i "/log_errors/s/log_errors.*/log_errors=On/" "$PHPINI"

  

    cd "$SCRIPTPATH" || {
        log "No path found: $SCRIPTPATH"
        #restore_server
        exit 1
    }

    # Copy default_ssl.conf and configure Apache
   # check_file default_ssl.conf
    cp -rf default_ssl.conf /etc/apache2/sites-enabled/
    sed -i '11 b; s/AllowOverride None\b/AllowOverride All/' /etc/apache2/apache2.conf
    sed -i 's/^User.*/User freeswitch/' /etc/apache2/apache2.conf
    sed -i 's/^Group.*/Group daemon/' /etc/apache2/apache2.conf
    sed -i "s/amol_debian.intalk.io/$domain_name/g" /etc/apache2/sites-enabled/default_ssl.conf

    systemctl enable apache2
    systemctl restart apache2
fi

# Check if OPENPBX directory exists or not
LINK_OR_DIR="/var/www/html/openpbx"
DIR_O="true"

if [[ ! -d "$LINK_OR_DIR" && ! -L "$LINK_OR_DIR" ]]; then
    DIR_O="false"
fi

log "Status OPENPBX: $DIR_O"
echo "Status OPENPBX: $DIR_O"


if [ "$DIR_O" = "false" ]; then
    cd "$SCRIPTPATH" || {
        log "No path found: $SCRIPTPATH"
        #restore_server
        exit 1
    }

    date_suffix=$(date +%Y%b%d)

    if [ -d "$OPENCC_FOLDER" ]; then
        mv "$OPENCC_FOLDER" "${OPENCC_FOLDER}_${date_suffix}" -rf
    fi
fi
INTALK_CODE_FILE=intalk.io
found_file=$(find . -type f -name "${INTALK_CODE_FILE}_v*.tgz")
# Get OpenCC code
if [ -e "$found_file" ]; then
    tar -xvzf "$found_file"
    mv OpenCC "$OPENCC_FOLDER" -f
    echo "Found $INTALK_CODE_FILE $INTALK_VERSION"

else
    if [ -e "$found_file" ]; then
        echo "Found $INTALK_CODE_FILE ..."
        tar -xzf "$found_file"
        tar -xvf "$found_file"
        mv OpenCC "$OPENCC_FOLDER" -f
    else
        echo "Not found"
        cd "$HTML_FOLDER" || {
            log "No path found: $HTML_FOLDER"
            #restore_server
            exit 1
        }
        git clone http://159.65.153.10/PHPProjects/OpenCC.git
        mv OpenCC openpbx -f
        cd - || {
            log "No path fo und "
            #restore_server
            exit 1
        }
    fi
fi


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

chown freeswitch:daemon /var/www/html/openpbx
chown freeswitch:daemon -R /var/www/html/openpbx
chown freeswitch:daemon -R "$OPENCC_FOLDER"

# Copy SSL certificates
if [ -f /etc/ssl/certs/opencc.crt ]; then
    rm -f "$OPENCC_FOLDER"/nodejs/opencc.crt "$OPENCC_FOLDER"/nodejs/opencc.key
    cp /etc/ssl/certs/opencc.* "$OPENCC_FOLDER"/nodejs/
    if [ ! -d /usr/local/freeswitch/certs ]  
    then
            mkdir /usr/local/freeswitch/certs >>/dev/null
    fi
    cp /etc/ssl/certs/opencc.* /usr/local/freeswitch/certs/
    cd /usr/local/freeswitch/certs/ || {
        log "No path found "
        #restore_server
        exit 1
    }
    echo '' >wss.pem && cat opencc.crt >>wss.pem && cat opencc.key >>wss.pem
    chown freeswitch.daemon wss.pem
    cd - || {
        log "No path found "
        #restore_server
        exit 1
    }
fi

# Extract certificate files
check_file cert.tar.gz
mv "$SCRIPTPATH"/cert.tar.gz /
cd /
tar -xvf /cert.tar.gz
cd - || {
    log "No path found "
    #restore_server
    exit 1
}

### ahiya thi baki
# Define an array of SQL files to copy
declare -a sql_files

sql_files=("intalk_db.sql" "intalk_tiss_db.sql" "intalk_appointment_db.sql")

# Loop through the SQL files and copy them if they exist
for file in "${sql_files[@]}"; do
    if [ -f "$file" ]; then
        scp "$file" "$OPENCC_FOLDER/DB_Schema_Changes/"
    fi
done

# Navigate to OPENCC_FOLDER and perform cleanup if necessary
cd "$OPENCC_FOLDER" || {
    log "No $OPENCC_FOLDER found "
    #restore_server
    exit 1
}

rm -f core/install/*.text
rm -f resources/config.php
rm -f tools
cd - || OPENCC_FOLDER

# Set permissions for directories
chown freeswitch:daemon -R /var/www/html/openpbx
chown freeswitch:daemon -R /usr/local/freeswitch

# Create an HTML file for page redirection
cat <<EOF >/var/www/html/index.html
<html>
<head>
<title>Page Moved</title>
</head>
<body>
This page has moved. Click <a id="url" href="#">here</a> to go to the new page.
<script>
var x = location.href.replace(/https?:\/\//i, "")
document.getElementById("url").href="https://"+x;
window.location.replace("https://"+x);
</script>
</body>
</html>
EOF

# Install additional packages
apt-get install -y lua-socket sngrep

# Modify configuration files
# sed -i 's/http:\/\/127.0.0.1\/hangup_data.php/http:\/\/127.0.0.1\/openpbx\/hangup_data.php/g' /usr/local/freeswitch/conf/autoload_configs/*
# sed -i 's/http:\/\/127.0.0.1\/app/http:\/\/127.0.0.1\/openpbx\/app/g' /usr/local/freeswitch/conf/autoload_configs/*

# Restart Apache
systemctl restart apache2

# Set permissions for directories
chown freeswitch:daemon -R /var/www/html/.htaccess
chown freeswitch:daemon -R /var/www/html/openpbx
# chown freeswitch:daemon -R /usr/local/freeswitch

# sed -i 's/http:\/\/127.0.0.1\/hangup_data.php/http:\/\/127.0.0.1\/openpbx\/hangup_data.php/g' /usr/local/freeswitch/conf/autoload_configs/*
# sed -i 's/http:\/\/127.0.0.1\/app/http:\/\/127.0.0.1\/openpbx\/app/g' /usr/local/freeswitch/conf/autoload_configs/*

# Create an .htaccess file for redirection
cat <<EOF >/var/www/html/.htaccess
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
EOF
systemctl restart apache2
chown freeswitch:daemon -R /var/www/html/.htaccess
chown freeswitch:daemon -R /var/www/html/openpbx
