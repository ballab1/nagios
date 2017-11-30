#!/bin/sh

# NCONF database backup
# Script by Y. Charton

# add (and adapt) the following line to the corresponding user's crontab:
# 50 23 * * * /usr/local/nconf/ADD-ONS/backup_db.sh

# MYSQL connection parameters (see config/mysql.php)
DBHOST=mysql
DBPORT=3306
DBNAME=nconf
DBUSER=bobb
DBPASS=123Oleary

# Other variables
DESTINATION=/usr/local/nagios/etc/nconf/dbBACKUP
DATE=`date +%Y%m%d%H%M%S`
KEEPDAY=30

# run backup
mysqldump --host=$DBHOST --port=$DBPORT -u $DBUSER --password=$DBPASS --single-transaction $DBNAME | gzip > $DESTINATION/$DBNAME-$DATE.sql.gz

# delete old backups
find $DESTINATION/ -type f -name "$DBNAME-*.sql.gz" -mtime +$KEEPDAY -exec rm {} \;

