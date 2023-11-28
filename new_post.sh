#! /bin/bash

chmod 777 *.sh
read -p "Have you generated a license successfully? [y/n]" ans
ip_addr=$(ip route get 8.8.8.8 | awk '/src/ {print $7}')
echo "$ip_addr"
case $ans in
    [Yy]*) 

    # function to run post service on particular service 
        post(){
        local ip="$1"
        local pass="$2"
        # local service="$3"
        if [ "$ip_addr" != "$ip" ]; 
        then
            #sshpass -p "$pass" ssh root@"$ip" "bash /root/post_$service.sh"
            sshpass -p "$pass" ssh root@"$ip" "bash /root/post.sh" | tee output.log
        else
            ./post.sh
        fi
        }
    
    # loop of services

        for v in app db media 
        do
           
        read -p "give ip for $v server" ip 
        read -p "give password for $ip" pass
        post "$ip" "$pass" #$v

        done

        echo "you have successfully completed post installation script"

        # run common config.ini script
       ./common_config.sh | tee > outut.log
    ;;
    [Nn]*) echo "please generate a license before executing this script....."
    ;;
esac
 
