# check config Startup 
#
#

if [ -z "$(ls -A ${NAGIOS_HOME}/etc)" ]; then
    echo "Empty Nagios config, copying Sample"
    cp -Rp /tmp/nagios_conf/etc/* ${NAGIOS_HOME}/etc/
fi

if [ -z "$(ls -A ${NAGIOS_HOME}/var)" ]; then
    echo "Empty Nagios VAR, copying Sample"
    cp -Rp /tmp/nagios_con/var/* ${NAGIOS_HOME}/var/
fi

if [ ! -d "${NAGIOS_HOME}/var/sql" ]; then
  mkdir -p ${NAGIOS_HOME}/var/sql
fi

chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/etc
chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/var
chown -R ${NAGIOS_USER}:${NAGIOS_GROUP} /var/log/httpd

now=$(date +"%m_%d_%Y")

/usr/bin/mysqldump --database lilac | gzip -c > ${NAGIOS_HOME}/var/sql/backup_$now.sql.gz

if [ -f "${NAGIOS_HOME}/var/sql/retore.sql" ]; then
   echo "drop database lilac;" | /usr/bin/mysql -u root
   echo "create database lilac;" | /usr/bin/mysql -u root
   /usr/bin/mysql -u root < "${NAGIOS_HOME}/var/sql/retore.sql"
   echo "grant all on lilac.* to 'lilac'@'localhost';" | /usr/bin/mysql -u root
   echo "flush privileges;" | /usr/bin/mysql -u root

   gzip "${NAGIOS_HOME}/var/sql/retore.sql"
   mv "${NAGIOS_HOME}/var/sql/retore.sql.gz" "${NAGIOS_HOME}/var/sql/retored_$now.sql.gz"

fi 



