#! /bin/bash

DB_USER=opencc
DB_DB=opencc
DB_PWD=opencc
EXTRA_DIALPLAN_SQL=intalk.io_extra_dialplans.sql
GW_UUID=$(uuidgen)
OPENCC_FOLDER=/var/www/html/openpbx

if [ ! -f /usr/local/post.txt ] 
then



#cd $OPENCC_FOLDER/DB_Schema_C*

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")


# mysql -f -u $DB_USER -p$DB_PWD opencc < $SCRIPTPATH/migration.sql
# mysql -f -u $DB_USER -p$DB_PWD opencc < $SCRIPTPATH/migration2.sql
# mysql -f -u $DB_USER -p$DB_PWD opencc < $SCRIPTPATH/migration3.sql



dos2unix intalk_*db.sql 2>>/dev/null
DB_DB_dummy=$DB_DB""_dummy
echo "Please provide mysql password (for root user)"
mysql -u root -pagami210 -e "SET GLOBAL group_concat_max_len = 10240; CREATE DATABASE $DB_DB_dummy; ALTER DATABASE $DB_DB_dummy CHARACTER SET utf8; ALTER DATABASE $DB_DB_dummy COLLATE utf8_general_ci; GRANT ALL PRIVILEGES on $DB_DB_dummy.* to 'opencc'@'%';"

mysql -f -u $DB_USER -p$DB_PWD $DB_DB_dummy < intalk_db.sql
mysql -f -u $DB_USER -p$DB_PWD $DB_DB_dummy < intalk_appointment_db.sql
mysql -f -u $DB_USER -p$DB_PWD $DB_DB_dummy < intalk_tiss_db.sql
mysql -f -u $DB_USER -p$DB_PWD $DB_DB_dummy < intalk_helpinbox_db.sql
mysql -f -u $DB_USER -p$DB_PWD $DB_DB_dummy < intalk_icici_db.sql
OLD_PWD=`pwd`
cd $OPENCC_FOLDER/DBDiff
## ./dbdiff server1.$DB_DB:server2.$DB_DB_dummy
rm -f migration.sql
./dbdiff server1.$DB_DB_dummy:server1.$DB_DB
if [ -f migration.sql ]; then
    dos2unix migration.sql  2>>/dev/null
    mv migration.sql $OLD_PWD
fi
cd - >>/dev/null 2>>/dev/null
echo "Please provide mysql password (for root user)"
mysql -u root -pagami210 -e "DROP DATABASE $DB_DB_dummy"

if [ -f migration.sql ]; then
    echo "Some correction in DB chema is required - Please provide mysql password (for root user)"
    mysql -f -u root -pagami210 opencc < migration.sql  2>>/dev/null
    #safer side - executing migration.sql one more time
    echo "Some final correction in DB chema is required - Please provide mysql password (for root user)"
    mysql -f -u root -pagami210 opencc < migration.sql  2>>/dev/null
else
    echo "No DB schema changes"
fi

#update DBschema for charset 
DB="$DB_DB"
(
   echo 'ALTER DATABASE `'"$DB"'` CHARACTER SET utf8 COLLATE utf8_general_ci;'
   mysql -u $DB_USER -p$DB_PWD "$DB" -e "SHOW TABLES" --batch --skip-column-names \
   | xargs -I{} echo 'ALTER TABLE `'{}'` CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;'
) \
| mysql -u $DB_USER -p$DB_PWD "$DB"



#update DB schema for timestamp correction
mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "ALTER TABLE v_login_campaign_break CHANGE available_time available_time TIMESTAMP NULL DEFAULT NULL;"
mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "ALTER TABLE v_login_campaign_break CHANGE offline_time offline_time TIMESTAMP NULL DEFAULT NULL"
mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "ALTER TABLE v_broadcasts_contacts_history CHANGE end_stamp end_stamp TIMESTAMP NULL DEFAULT NULL;"
mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "ALTER TABLE v_broadcasts_contacts_history CHANGE start_stamp start_stamp TIMESTAMP NULL DEFAULT NULL;"
#mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "ALTER TABLE v_call_state CHANGE created_at created_at TIMESTAMP NULL DEFAULT NULL;"
#mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "ALTER TABLE v_call_state CHANGE updated_at updated_at TIMESTAMP NULL DEFAULT NULL;"
mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "ALTER TABLE v_login_campaign CHANGE campaign_login_time campaign_login_time TIMESTAMP NULL DEFAULT NULL;"
mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "ALTER TABLE v_login_campaign CHANGE campaign_logout_time campaign_logout_time TIMESTAMP NULL DEFAULT NULL;"
mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "ALTER TABLE v_break CHANGE deleted_at deleted_at TIMESTAMP NULL DEFAULT NULL;"

#read domain_uuid and domain name
domain_uuid=`mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "select domain_uuid from v_domains where domain_enabled='true' and domain_description='Default Domain' limit 1;"`
domain_name=`mysql -p$DB_PWD -N  -u $DB_USER $DB_DB -Be "select domain_name from v_domains where domain_enabled='true' and domain_description='Default Domain' limit 1;"`

domain_uuid_ho=`mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "select domain_uuid from v_domains where domain_enabled='true' and domain_description Like '%sub Domain%' limit 1;;"`

domain_name_ho=`mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "select domain_name from v_domains where domain_enabled='true' and domain_description Like '%sub Domain%' limit 1;;"`

#execute updated sql statement to create dialplans in FreeSWITCH
mysql -f -p$DB_PWD -u $DB_USER $DB_DB < $EXTRA_DIALPLAN_SQL
    

#update websocket settings
mysql -p$DB_PWD -u $DB_USER $DB_DB -Be 'INSERT v_websocket_setting SET domain_uuid="'$domain_uuid'", call_socket_url = "wss://'$domain_name':8443", chatsocket_url = "https://'$domain_name':8888", freeswitch_ws = "wss://'$domain_name'", freeswitch_port=9000, freeswitch_url = "'$domain_name'" ;'

#subdomain
mysql -p$DB_PWD -u $DB_USER $DB_DB -Be 'INSERT v_websocket_setting SET domain_uuid="'$domain_uuid_ho'", call_socket_url = "wss://'$domain_name':8443", chatsocket_url = "https://'$domain_name':8888", freeswitch_ws = "wss://'$domain_name'", freeswitch_port=9000, freeswitch_url = "'$domain_name_ho'" ;'

#update wss for FreeSwitch
internal_profile_uuid=`mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "SELECT sip_profile_uuid FROM v_sip_profiles where sip_profile_name='internal' LIMIT 1;"`
new_uuid=$(uuidgen)
mysql -p$DB_PWD -u $DB_USER $DB_DB -Be "INSERT v_sip_profile_settings  SET sip_profile_setting_uuid ='$new_uuid', sip_profile_uuid = '$internal_profile_uuid', sip_profile_setting_name='wss-binding' , sip_profile_setting_value=':9000', sip_profile_setting_enabled='true', sip_profile_setting_description=NULL ;"

#adding default gateway
mysql -p$DB_PWD -u $DB_USER $DB_DB -Be "INSERT INTO v_gateways (gateway_uuid, domain_uuid, gateway, username, password, distinct_to, auth_username, realm, from_user, from_domain, proxy, register_proxy, outbound_proxy, expire_seconds, register, register_transport, retry_seconds, extension, ping, caller_id_in_from, supress_cng, sip_cid_type, codec_prefs, channels, extension_in_contact, context, profile, hostname, enabled, description) VALUES (uuid(),	'$domain_uuid_ho',	'PSTN_PRI',	'not-used',	'not-used',	NULL,	NULL,	NULL,	NULL,	NULL,	'127.0.0.1',	NULL,	NULL,	800,	'false',	NULL,	30,	NULL,	NULL,	NULL,	NULL,	NULL,	NULL,	0,	NULL,	'public',	'internal',	NULL,	'true',	NULL);"
mysql -p$DB_PWD -u $DB_USER $DB_DB -Be "UPDATE v_sip_profile_settings SET sip_profile_setting_value='/usr/local/freeswitch/certs' WHERE sip_profile_uuid = '$internal_profile_uuid' and sip_profile_setting_name = 'tls-cert-dir' ;"


#update SIP ports of FreeSWITCH
mysql -p$DB_PWD -u $DB_USER $DB_DB -Be "UPDATE v_vars SET var_value = 6050 where var_name = 'internal_sip_port' ;"
mysql -p$DB_PWD -u $DB_USER $DB_DB -Be "UPDATE v_vars SET var_value = 6051 where var_name = 'internal_tls_port' ;"

#Version
mysql -p$DB_PWD -N -u $DB_USER $DB_DB -Be "INSERT INTO version (table_name,table_version) VALUES ('location',   9), ('location_attrs',  1), ('subscriber',      7), ('version', 1);"



#Add group type operator if does not exist for all sub domains/locations
mysql -u $DB_USER -p$DB_PWD $DB_DB -e "INSERT INTO v_groups (group_uuid, domain_uuid, group_name, group_type)
VALUES (UUID(), NULL, 'Operator', 'operator');"



#default permissions for supervisors
mysql -u $DB_USER -p$DB_PWD $DB_DB -e "INSERT INTO v_permission (permission_uuid, group_uuid,permission_values)
(SELECT UUID(), group_uuid, '[\"Live Dashboard\",\"Live Data\",\"Team status\",\"Call in queue\",\"Logout User\",\"Switch Queue\",\"Call-Hang-up\",\"Transfer Call\",\"Eavesdrop\",\"Conference\",\"whisper\",\"List Statistics\",\"Queue Detail\",\"Supervisor Users Status\",\"Supervisor Users Logout\",\"Campaign Detail\",\"Analytics\",\"Analytics Data\",\"Inbound Dashboard\",\"Outbound Dashboard\",\"Manual Dashboard\",\"Disposition summary\",\"CallBack List\",\"System Disposition Summary Report\",\"Leads\",\"Voice Calls Trend\",\"Average Call Duration Trend\",\"Total Calls\",\"Average Call Duration\",\"Non Connected Calls\",\"Agent Happiness\",\"Call Counts\",\"Call Graph Date wise\",\"Call Graph Status wise\",\"Call-History-Supervisor\",\"cdr-call-detailed-report\",\"Manual Outbound Call Detail Report\",\"Auto Call Distribution Detail Report\",\"Campaign Call Distribution Summary Report\",\"Agent Call Distribution Summary Report\",\"Agent Productivity Report\",\"Abandoned Calls Report\",\"Inbound Performance Report\",\"CallBack Report\",\"Login History Report\",\"Customer Feedback Summary Report\",\"Calls On IVR Report\",\"Calls On IVR Summary Report\",\"Auto Call Distribution Report\",\"Call-List Summary Report\",\"MissedCall Service Summary Report\",\"Call Blaster Report\",\"Call Blaster Summary Report\",\"Report\",\"Manual Outbound Performance Report\",\"Call Distribution Detail Report New\",\"Administrator\",\"Download Bulk Recording\",\"Setting\",\"Campaign Data Migration\",\"System Statstics\",\"Apps\",\"Users\",\"Campaign\",\"Queues\",\"Add Agent Queues\",\"Call List\",\"Abandoned Call Management\",\"Queue Mapping\",\"Disposition List\",\"Scripts\",\"Breaks\",\"DNC List\",\"Recordings\",\"MissedCall Service\",\"Pre Define Recordings\",\"Email Configuration\",\"Email Template\",\"Msg Configuration\",\"Msg Template\",\"Report Scheduler\",\"VIP Caller\",\"IVR\",\"Call Block List\",\"Crm Design\",\"Other\",\"Recording\",\"Call Rating\",\"Change Password\",\"Profile\",\"Export\",\"Report Column Selection\",\"Notification\",\"Date Filter Check\",\"Bulk List\",\"Call-Dialpad\",\"Calling\",\"Redial\",\"Hold\",\"DTMF\",\"Play File\",\"Mute\",\"Blind Transfer\",\"Attended Transfer\",\"Consultation Hold\",\"Call Conference\",\"Recording Stop\",\"Hang-up\",\"Disposition\",\"Call-Info\"]' 
FROM v_groups
WHERE group_type = 'supervisor' and domain_uuid is NULL );"

#default permissions for operators
mysql -u $DB_USER -p$DB_PWD $DB_DB -e "INSERT INTO v_permission (permission_uuid, group_uuid,permission_values)
(SELECT UUID(), group_uuid, '[\"Live Dashboard\",\"Live Data\",\"Team status\",\"Call in queue\",\"Logout User\",\"Switch Queue\",\"Call-Hang-up\",\"Transfer Call\",\"Eavesdrop\",\"Conference\",\"whisper\",\"List Statistics\",\"Queue Detail\",\"Supervisor Users Status\",\"Supervisor Users Logout\",\"Campaign Detail\",\"Analytics\",\"Analytics Data\",\"Inbound Dashboard\",\"Outbound Dashboard\",\"Manual Dashboard\",\"Disposition summary\",\"CallBack List\",\"System Disposition Summary Report\",\"Leads\",\"Voice Calls Trend\",\"Average Call Duration Trend\",\"Total Calls\",\"Average Call Duration\",\"Non Connected Calls\",\"Agent Happiness\",\"Call Counts\",\"Call Graph Date wise\",\"Call Graph Status wise\",\"Call-History-Supervisor\",\"cdr-call-detailed-report\",\"Manual Outbound Call Detail Report\",\"Auto Call Distribution Detail Report\",\"Campaign Call Distribution Summary Report\",\"Agent Call Distribution Summary Report\",\"Agent Productivity Report\",\"Abandoned Calls Report\",\"Inbound Performance Report\",\"CallBack Report\",\"Login History Report\",\"Customer Feedback Summary Report\",\"Calls On IVR Report\",\"Calls On IVR Summary Report\",\"Auto Call Distribution Report\",\"Call-List Summary Report\",\"MissedCall Service Summary Report\",\"Call Blaster Report\",\"Call Blaster Summary Report\",\"Report\",\"Manual Outbound Performance Report\",\"Call Distribution Detail Report New\",\"Other\",\"Recording\",\"Call Rating\",\"Change Password\",\"Profile\",\"Export\",\"Report Column Selection\",\"Notification\",\"Date Filter Check\",\"Bulk List\",\"Call-Dialpad\",\"Calling\",\"Redial\",\"Hold\",\"DTMF\",\"Play File\",\"Mute\",\"Blind Transfer\",\"Attended Transfer\",\"Consultation Hold\",\"Call Conference\",\"Recording Stop\",\"Hang-up\",\"Disposition\",\"Call-Info\",\"Apps\",\"Users\",\"Campaign\",\"Queues\",\"Add Agent Queues\",\"Call List\"]' 
FROM v_groups
WHERE group_type = 'operator' and domain_uuid is NULL );"

#default permissions for agent
mysql -u $DB_USER -p$DB_PWD $DB_DB -e "INSERT INTO v_permission (permission_uuid, group_uuid,permission_values)
(SELECT UUID(), group_uuid, '[\"Dashboard\",\"Campaign-Detail\",\"Login-History\",\"Call-History-Agent\",\"Switch-Queue\",\"List\",\"Disposition Summary\",\"Agent Status Summary\",\"Avg Inbound Talk Time\",\"Today Call Counts\",\"Callback history\",\"Avg Outbound Talk Time\",\"Latest 10 Call History Details\",\"Other\",\"Break\",\"Recording\",\"Set Auto Call\",\"Break Aftre This Call\",\"Logout After This Call\",\"Auto Call Off After This Call\",\"Change Password\",\"Show Masking Number\",\"Call-Dialpad\",\"Today-call-history\",\"Calling\",\"Redial\",\"Hold\",\"DTMF\",\"Play File\",\"Mute\",\"Blind Transfer\",\"Attended Transfer\",\"Consultation Hold\",\"Call Conference\",\"Recording Stop\",\"Hang-up\",\"Disposition\",\"Call-Info\"]' 
FROM v_groups
WHERE group_type = 'agent' and domain_uuid is NULL );"

#update domain_uuid for v_groups table 
mysql -u $DB_USER -p$DB_PWD $DB_DB -e "update v_groups set domain_uuid = (select domain_uuid from v_domains where domain_parent_uuid is not null and domain_enabled='true') where domain_uuid is null";

mysql -p$DB_PWD -u $DB_USER $DB_DB -Be 'INSERT INTO `v_dialplans` (`domain_uuid`, `dialplan_uuid`, `app_uuid`, `hostname`, `dialplan_context`, `dialplan_name`, `dialplan_number`, `dialplan_continue`, `dialplan_xml`, `dialplan_order`, `dialplan_enabled`, `dialplan_description`, `dialplans_lang_code`, `caller_id`, `deleted_at`) VALUES ("'$domain_uuid'",  "72d65b02-368b-4724-9d74-fd3c7a6f04a8", "742714e5-8cdf-32fd-462c-cbe7e3d655db", NULL, "${domain_name}", "wait", "wait", "true", "<extension name=\"wait\" continue=\"true\" uuid=\"72d65b02-368b-4724-9d74-fd3c7a6f04a8\">\\n <condition field=\"destination_number\" expression=\"^wait(\\d+)$\">\\n   <action application=\"sleep\" data=\"$1\"/>\\n    <action application=\"hangup\" data=\"NO_ANSWER\"/>\\n  </condition>\\n</extension>\\n",  25, "true", NULL, NULL, NULL, NULL);';



fi