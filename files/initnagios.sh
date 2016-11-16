# First Startup Script
#
#


# init MariaDB for Lilac
systemctl start mariadb
echo "create database lilac;" | /usr/bin/mysql -u root
echo "create user 'lilac'@'localhost' identified by 'lilac';" | /usr/bin/mysql -u root
echo "grant all on lilac.* to 'lilac'@'localhost';" | /usr/bin/mysql -u root
echo "flush privileges;" | /usr/bin/mysql -u root


# Delete this script
/bin/rm -f /etc/rc.d/startup/initnagios.sh



