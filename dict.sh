#! /bin/bash


read -p "please give the ip of instance: " ip_input 
read -p "please give the password of your $ip_input: " pass_input


declare -A instance_details

instance_details["$ip_input"]="$pass_input"

for key in "${!instance_details[@]}"; do
echo "$key"
  echo "$key: ${instance_details[$key]}"
done