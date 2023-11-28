#! /bin/bash
echo "how many instance you have ?"
read -r no_instance
declare -A instance_details
for ((i = 1; i <= no_instance; i++)); do
    read -p "Please give the IP of instance $i: " ip_input
    read -p "Please give the password for $ip_input: " pass_input
    instance_details["$ip_input"]="$pass_input"
done

declare -A instance_details
for ((i = 1; i <= no_instance; i++)); do
    read -p "Please give the IP of instance $i: " ip_input
    read -p "Please give the password for $ip_input: " pass_input
    instance_details["$ip_input"]="$pass_input"
done

for element in "${!instance_details[@]}"; do
ip_addr=$(ip route get 8.8.8.8 | awk '/src/ {print $7}')
 if [ "${element}" != "$ip_addr" ]; then
      sshpass -p "${instance_details[$element]}" ssh root@"${element}" 'bash /root/post.sh' | tee output.log
 else
    ./post.sh | tee output.log
 fi 
 done