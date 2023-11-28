#!/bin/bash

# Log file
LOG_FILE="/var/log/startm.log"

# Function to log messages
log() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" >>"$LOG_FILE"
}

found_file=$(find . -type f -name "intalk.io_v*.tgz")
freeswitch_tar=$(find . -type f -name "freeswitch*.tgz")

ip_addr=$(ip route get 8.8.8.8 | awk '/src/ {print $7}')

do_connection() {
    local ip="$1"
    local pass="$2"
    if [ "$ip" != "$ip_addr" ]; then
        echo "sshpass -p '$pass' ssh root@$ip"
        if sshpass -p "$pass" ssh root@"$ip" 'bash -s' -- "$ip" <coninit.sh; then
            echo "Connection established with $ip"
        else
            echo "Connection failed with $ip"
            read -p "Do you still want to continue (yes/no)? " yn
            if [[ "$yn" =~ ^[Nn][Oo]$ ]]; then
                exit 1
            fi
        fi
    fi
}

# install database service
db_service() {
    local ip="$1"
    local pass="$2"
    sshpass -p"$pass" scp -r common.sh intalk_appointment_db.sql intalk_tiss_db.sql intalk_helpinbox_db.sql intalk_icici_db.sql intalk_db.sql intalk.io_extra_dialplans.sql lib64 migration.sql migration2.sql migration3.sql db_service.sh  post.sh root@"$ip":/root
  #  sshpass -p "$pass" ssh  root@"$ip" 'bash /root/common.sh' | tee output.log
    sshpass -p "$pass" ssh root@"$ip" 'bash /root/db_service.sh' | tee output.log
}

# app service
app_service() {
    local ip="$1"
    local pass="$2"
    sshpass -p"$pass" scp -r common.sh default_ssl.conf intalk_db.sql intalk_tiss_db.sql intalk_appointment_db.sql app_service.sh  post.sh root@"$ip":/root
    sshpass -p"$pass" scp "$found_file" cert.tar.gz root@"$ip":/root
  #  sshpass -p "$pass" ssh  root@"$ip" 'bash /root/common.sh' | tee output.log
    sshpass -p "$pass" ssh root@"$ip" 'bash /root/app_service.sh' | tee output.log
}

# media service
media_service() {
    local ip="$1"
    local pass="$2"
    sshpass -p"$pass" scp -r common.sh "$found_file"  media_service.sh  lualib64_5.3.tgz lualib_5.3.tgz post.sh root@"$ip":/root
    sshpass -p"$pass" scp "$freeswitch_tar" root@"$ip":/root
  #  sshpass -p "$pass" ssh  root@"$ip" 'bash /root/common.sh' | tee output.log
    sshpass -p "$pass" ssh root@"$ip" 'bash /root/media_service.sh' | tee output.log
}

# node service
node_service() {
    local ip="$1"
    local pass="$2"
    sshpass -p"$pass" scp -r common.sh opencc_node chatbox_node node_service.sh post.sh root@"$ip":/root
    sshpass -p"$pass" scp "$found_file" root@"$ip":/root
  #  sshpass -p "$pass" ssh  root@"$ip" 'bash /root/common.sh' | tee output.log
    sshpass -p "$pass" ssh root@"$ip" 'bash /root/node_service.sh' | tee output.log
}

echo "It is a multi-instance installation"
echo "how many instance you have ?"
read -r no_instance

#old part
# declare -a inst_arr
# for ((i = 1; i <= no_instance; i++)); do
#     echo "Give IP of your instance $i"
#     read -r "ip_$i"
#     inst_arr+=("ip_$i")
# done

# #new part
declare -A instance_details
for ((i = 1; i <= no_instance; i++)); do
    read -p "Please give the IP of instance $i: " ip_input
    read -p "Please give the password for $ip_input: " pass_input
    instance_details["$ip_input"]="$pass_input"
done
# for key in "${!instance_details[@]}"; do
#     echo "IP: $key, Password: ${instance_details[$key]}"
# done

for element in "${!instance_details[@]}"; do
    #echo "${element}"
    do_connection "${element}" "${instance_details[$element]}"
    for service in app_service db_service media_service node_service; do
        read -p "Do you want to install $service on ${element}? (y/n): " yn
        case $yn in
        [Yy]*)
            if [ "${element}" != "$ip_addr" ]; then
                "$service" "${element}" "${instance_details[$element]}" && echo "$service is starting to installed"
            else
                sh "$service".sh
            fi
            
          #  echo "$service is starting to installed on ${element}"
          #  log "$service is starting to installed on ${element}"
            ;;
        [Nn]*)
            log "User doesn't want to install $service on this ${element}"
            ;;
        esac
    done
done
