#! /bin/bash
DB_USER=opencc
DB_DB=opencc
DB_PWD=opencc
OPENCC_FOLDER=/var/www/html/openpbx
SOUND_FOLDER=/usr/loacl/freeswitch/sounds

if [ ! -f /usr/local/post.txt ] 
then



#.env updation for redis IP
ENV_FILE=$OPENCC_FOLDER/cc/.env
sed -i.bak "/APP_PATH=/c APP_PATH=\'\'" $ENV_FILE

if [ ! -d $OPENCC_FOLDER/cc/public/upload/pdf ]; then
    mkdir $OPENCC_FOLDER/cc/public/upload/pdf
    chown freeswitch.daemon $OPENCC_FOLDER/cc/public/upload/pdf
fi

if [ -f $OPENCC_FOLDER/format_cdr.conf.xml ]; then
    cp -f $OPENCC_FOLDER/format_cdr.conf.xml /usr/local/freeswitch/conf/autoload_configs/
    chown freeswitch:daemon /usr/local/freeswitch/conf/autoload_configs/format_cdr.conf.xml
fi

if [ -f $OPENCC_FOLDER/change_recording_permission.bin ]; then
    rm -f /usr/local/freeswitch/change_recording_permission.bin
    cp -f $OPENCC_FOLDER/change_recording_permission.bin /usr/local/freeswitch/change_recording_permission.bin
    chmod +s  /usr/local/freeswitch/change_recording_permission.bin
fi


#add crontab entry for running CallCenter script

echo "* * * * * /usr/bin/wget -O - http://127.0.0.1/cc/gettenmails >/dev/null 2>&1" > .temp.cron
echo "*/10 * * * * /usr/bin/sh /var/www/html/openpbx/collect_sysstat.sh" >> .temp.cron
crontab -u freeswitch -l | cat -  .temp.cron >.temp2.cron
crontab -u freeswitch .temp2.cron
crontab -u freeswitch -l

#keep ntp time update under root permission
echo "0 */3 * * * ntpdate pool.ntp.org" > .temp.cron
echo "* * * * * /usr/bin/sh /var/www/html/openpbx/tools/service_status.sh" >> .temp.cron
echo "*/5 * * * * /usr/bin/sh /var/www/html/openpbx/tools/insert_service_status.sh" >> .temp.cron

crontab -l | cat -  .temp.cron >.temp2.cron
crontab  .temp2.cron
crontab -l

rm -f .temp.cron .temp2.cron

mkdir /usr/local/freeswitch/recordings
chown freeswitch:daemon -R /usr/local/freeswitch/recordings
chmod 777 /usr/local/freeswitch/recordings

#version
cp version.csv /var/lib/mysql/opencc/
chown mysql:mysql /var/lib/mysql/opencc/version.csv
chmod 666 /var/lib/mysql/opencc/version.csv
#mysql -u $DB_USER -p$DB_PWD $DB_DB  << EOF
#LOAD DATA INFILE 'version.csv'
#    INTO TABLE version
#FIELDS TERMINATED BY ','
#ENCLOSED BY '"'
#LINES TERMINATED BY '\n'
#IGNORE 1 ROWS;
#EOF
croncmd="/usr/bin/sh /var/www/html/openpbx/tools/service_status.sh > /var/log/service_status.log 2>&1"
cronjob="* * * * * $croncmd"
#( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -

#change ownership of php session folder
chown freeswitch:daemon /var/lib/php/session /var/lib/php/wsdlcache -R



fi