#!/bin/bash

config_file="config.ini"
ip_addr=$(ip route get 8.8.8.8 | awk '/src/ {print $7}')

# Check if the config.ini file exists
if [ ! -f "$config_file" ]; then
    echo "Error: $config_file does not exist."
    exit 1
fi

echo "Let's start to configure $config_file..."

# Update DB_HOST
read -p "Please provide the IP where you have installed the Database service: " db_ip
sed -i "/DB_HOST/s/DB_HOST.*/DB_HOST=$db_ip/" "$config_file"

# Update ESL_IP, REDIS_HOST, and Kamailio_IP
read -p "Please provide the IP where you have installed the Media service: " media_ip
sed -i "/ESL_IP/s/ESL_IP.*/ESL_IP=$media_ip/" "$config_file"
sed -i "/REDIS_HOST/s/REDIS_HOST.*/REDIS_HOST=$media_ip/" "$config_file"
sed -i "/Kamailio_IP/s/Kamailio_IP.*/Kamailio_IP=$media_ip/" "$config_file"

# Update REPORT_DB_HOST
read -p "Please provide the IP where you have installed the Report Database service: " report_db_ip
sed -i "/REPORT_DB_HOST/s/REPORT_DB_HOST.*/REPORT_DB_HOST=$report_db_ip/" "$config_file"

# Update Kamailio_PORT
read -p "Please provide the port of Kamailio: " kamailio_port
sed -i "/Kamailio_PORT/s/Kamailio_PORT.*/Kamailio_PORT=$kamailio_port/" "$config_file"

echo "Configuration of $config_file completed."

# copy the config.ini file everywhere
echo "how many instance you have ?"
read -r no_instance
declare -A instance_details
for ((i = 1; i <= no_instance; i++)); do
    read -p "Please give the IP of instance $i: " ip_input
    read -p "Please give the password for $ip_input: " pass_input
    instance_details["$ip_input"]="$pass_input"
done

for element in "${!instance_details[@]}"; do 
    if [ "$ip_addr" != "${element}" ]; 
    then
    sshpass -p "${instance_details[$element]}" scp "$config_file" root@"${element}":/var/www/html/openpbx
    echo "the file is configured at ${element} "
    else scp "$config_file" /var/www/html/openpbx
    fi
   
done