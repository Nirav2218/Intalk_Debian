#! /bin/bash
DB_USER=opencc
DB_DB=opencc
DB_PWD=opencc
OPENCC_FOLDER=/var/www/html/openpbx
SOUND_FOLDER=/usr/loacl/freeswitch/sounds


if [ ! -f /usr/local/post.txt ] 
then


if [ -d $OPENCC_FOLDER/scripts ]; then
	if [ -L /usr/local/freeswitch/scripts ]; then
		rm -f /usr/local/freeswitch/scripts
	elif [ -d /usr/local/freeswitch/scripts ]; then
		mv /usr/local/freeswitch/scripts /usr/local/freeswitch/scripts_X
	fi
	ln -s $OPENCC_FOLDER/scripts /usr/local/freeswitch/scripts
else
	cp $OPENCC_FOLDER/serv/*.lua /usr/local/freeswitch/scripts/
	chown freeswitch:daemon /usr/local/freeswitch/scripts/*.lua
fi

#update library files rquired by LUA to connect to redis or anyother web API
if [ -d $OPENCC_FOLDER/scripts/usr ]; then
    scp -r $OPENCC_FOLDER/scripts/usr/*  /usr/
fi


#copy recording/voice files to freeswitch directory
if ! [ -d "/usr/local/freeswitch/recordings/$domain_name" ]; then
    mkdir /usr/local/freeswitch/recordings/$domain_name
fi
cp -rf $OPENCC_FOLDER/IP-BASED /usr/local/freeswitch/recordings/$domain_name/
cp -rf $OPENCC_FOLDER/*.wav /usr/local/freeswitch/recordings/$domain_name/
chown freeswitch:daemon /usr/local/freeswitch/recordings/$domain_name* -R


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

sofia_at=`grep "mod_sofia" /usr/local/freeswitch/conf/autoload_configs/modules.conf.xml -n | cut -d':' -f 1`
#esl not required
#esl_at=`grep "mod_esl" /usr/local/freeswitch/conf/autoload_configs/modules.conf.xml -n | cut -d':' -f 1`
fcdr_at=`grep "mod_format_cdr" /usr/local/freeswitch/conf/autoload_configs/modules.conf.xml -n | cut -d':' -f 1`
distributor_at=`grep "mod_distributor" /usr/local/freeswitch/conf/autoload_configs/modules.conf.xml -n | cut -d':' -f 1`

if [ "$sofia_at" == "" ]; then
   # as no sofia module - add it at randomly say at line 5
   sed -i '5 a <load module="mod_sofia"/>' /usr/local/freeswitch/conf/autoload_configs/modules.conf.xml
   $sofia_at = 5
fi
if [ "$fcdr_at" == "" ]; then
   sed -i ''$sofia_at' a <load module="mod_format_cdr"/>' /usr/local/freeswitch/conf/autoload_configs/modules.conf.xml
fi
if [ "$distributor_at" == "" ]; then
   sed -i ''$sofia_at' a <load module="mod_distributor"/>' /usr/local/freeswitch/conf/autoload_configs/modules.conf.xml
fi

if [ -f lualib64_5.3.tgz ]; then
    cp lualib64_5.3.tgz /
    cd /
    tar -xzf lualib64_5.3.tgz
    cd -
fi

if [ -f lualib_5.3.tgz ]; then
    cp lualib_5.3.tgz /
    cd /
    tar -xzf lualib_5.3.tgz
    cd -
fi

#update configuration for perl scripts
cd $OPENCC_FOLDER/serv
dos2unix *.pl
dos2unix *.sh
##sed -i.bak "/\$database = '/c \$database = '"$DB_DB"';" *.pl
##sed -i "/\$username = '/c \$username = '"$DB_USER"';" *.pl
##sed -i "/\$password = '/c \$password = '"$DB_PWD"';" *.pl
cd -

if [ ! -h $OPENCC_FOLDER/recordings ]; then
    ln -s /usr/local/freeswitch/recordings $OPENCC_FOLDER/recordings
fi 

#add crontab entry for running CallCenter script
echo "* * * * * /usr/bin/sh "$OPENCC_FOLDER"/serv/redis-campaign-blast.sh" > .temp.cron
echo "* * * * * /usr/bin/sh "$OPENCC_FOLDER"/serv/redis-campaign-autoblast.sh" >> .temp.cron
echo "#* * * * * sleep 30 && /usr/bin/sh "$OPENCC_FOLDER"/serv/redis-campaign-blast.sh" >> .temp.cron
echo "#* * * * * sleep 30 && /usr/bin/sh "$OPENCC_FOLDER"/serv/redis-campaign-autoblast.sh" >> .temp.cron
echo "1 0 * * * /usr/bin/sh "$OPENCC_FOLDER"/Archive_LogFiles.sh" >> .temp.cron
#echo "* * * * * chmod 775 /usr/local/freeswitch/recordings -R" >> .temp.cron
#echo "* * * * * chown freeswitch.daemon /usr/local/freeswitch/recordings -R" >> .temp.cron
echo "0 0 28 * * /usr/bin/sh /var/www/html/openpbx/recording_folder_permission.sh" >> .temp.cron
echo "* * * * * /usr/bin/wget -O - http://127.0.0.1/cc/gettenmails >/dev/null 2>&1" >> .temp.cron
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



mkdir -p /var/www/html/openpbx/recordings/temp
chmod 777 /var/www/html/openpbx/recordings/temp
chown freeswitch:daemon -R /var/www/html/openpbx/recordings

#2904 - voice prompt "You are the only person in this conference" gets played while doing conference
mv $SOUND_FOLDER/en/us/callie/conference/8000/conf-alone.wav $SOUND_FOLDER/en/us/callie/conference/8000/conf-alone.wavX 2>>/dev/null
mv $SOUND_FOLDER/en/us/callie/conference/16000/conf-alone.wav $SOUND_FOLDER/en/us/callie/conference/16000/conf-alone.wavX 2>>/dev/null
mv $SOUND_FOLDER/en/us/callie/conference/32000/conf-alone.wav $SOUND_FOLDER/en/us/callie/conference/32000/conf-alone.wavX 2>>/dev/null
mv $SOUND_FOLDER/en/us/callie/conference/48000/conf-alone.wav $SOUND_FOLDER/en/us/callie/conference/48000/conf-alone.wavX 2>>/dev/null



cat > /usr/local/freeswitch/conf/autoload_configs/hiredis.conf.xml  <<- EOM
<configuration name="hiredis.conf" description="mod_hiredis">
  <profiles>
    <profile name="default">
      <connections>
        <connection name="primary">
          <param name="hostname" value="127.0.0.1"/>
          <param name="password" value="opencc"/>
          <param name="port" value="7379"/>
          <param name="timeout_ms" value="500"/>
        </connection>
        <connection name="secondary">
          <param name="hostname" value="localhost"/>
          <param name="password" value=""/>
          <param name="port" value="6379"/>
          <param name="timeout_ms" value="500"/>
        </connection>
      </connections>
      <params>
        <param name="ignore-connect-fail" value="true"/>
      </params>
    </profile>
 <profile name="limitredis">
      <connections>
        <connection name="primary">
          <param name="hostname" value="127.0.0.1"/>
          <param name="password" value="opencc"/>
          <param name="port" value="7379"/>
          <param name="timeout_ms" value="500"/>
        </connection>
        <connection name="secondary">
          <param name="hostname" value="localhost"/>
          <param name="password" value=""/>
          <param name="port" value="6379"/>
          <param name="timeout_ms" value="500"/>
        </connection>
      </connections>
      <params>
        <param name="ignore-connect-fail" value="true"/>
      </params>
    </profile>
  </profiles>
</configuration>
EOM

sed -i 's/http:\/\/127.0.0.1\/hangup_data.php/http:\/\/127.0.0.1\/openpbx\/hangup_data.php/g' /usr/local/freeswitch/conf/autoload_configs/*
sed -i 's/http:\/\/127.0.0.1\/app/http:\/\/127.0.0.1\/openpbx\/app/g' /usr/local/freeswitch/conf/autoload_configs/*


 fs_cli -x 'reloadxml';
 fs_cli -x 'reload mod_hiredis';
 fs_cli -x "reload mod_format_cdr"
 fs_cli -x "reload mod_xml_cdr"
 fs_cli -x "reload mod_sofia"
fs_cli -x "reload mod_callcenter"

cd $SCRIPTPATH;

php phpinfo.php $domain_uuid

#start all services
systemctl restart opencc_nodejs
systemctl restart apache2
echo "Done .........";
echo "init" > /usr/local/post.txt

read -p "give the ip where you've installed app service" ip
sed -i "s/http:\/\/$ip\/hangup_data.php/http:\/\/$ip\/openpbx\/hangup_data.php/g" /usr/local/freeswitch/conf/autoload_configs/*
sed -i "s/http:\/\/$ip\/app/http:\/\/$ip\/openpbx\/app/g" /usr/local/freeswitch/conf/autoload_configs/*


fi