#!/usr/bin/env bash

set -x

MYSQL_PASSWORD=admin

TEAMCITY_DB_HOST=localhost
TEAMCITY_DB_NAME=teamcity
TEAMCITY_DB_USER=teamcity
TEAMCITY_DB_PASS=teamcity

TEAMCITY_USER=teamcity
TEAMCITY_GROUP=teamcity

TEAMCITY_BACKUP="/vagrant/restore/$(hostname).zip"

# NOTE: The TEAMCITY_DIR variable _must_ end in TeamCity unless some
# faffage is done because that's the top level name in the tgz.  It's
# totally possible to rename this but it adds fragility for minimal
# gain.
TEAMCITY_DIR=/opt/TeamCity
TEAMCITY_DATA_DIR=${TEAMCITY_DIR}/data

TEAMCITY_VERSION=10.0.5
TEAMCITY_TGZ=TeamCity-${TEAMCITY_VERSION}.tar.gz
TEAMCITY_URL=http://download.jetbrains.com/teamcity/$TEAMCITY_TGZ

MYSQL_JDBC_VERSION=5.1.41
MYSQL_JDBC_JAR=mysql-connector-java-${MYSQL_JDBC_VERSION}.jar
MYSQL_JDBC_URL=http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/${MYSQL_JDBC_VERSION}/${MYSQL_JDBC_JAR}

TEAMCITY_DATABASE_PROPERTIES=$TEAMCITY_DATA_DIR/config/database.properties

if [ -d $TEAMCITY_DATA_DIR ]; then
    echo "Server is already provisioned"
    exit 0
fi

# On the backup machine, this does not exist;
mkdir -p /mnt/data

# Install various packages required to run TeamCity
apt-get update

# Configure MySQL for TeamCity
# https://confluence.jetbrains.com/display/TCD9/How+To...#HowTo...-ConfigureNewlyInstalledMySQLServer
mkdir -p /etc/mysql/conf.d
cp /vagrant/files/server/teamcity.cnf /etc/mysql/conf.d

# Install MySQL
echo mysql-server mysql-server/root_password password $MYSQL_PASSWORD | debconf-set-selections
echo mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD | debconf-set-selections
apt-get install -y mysql-server

## Finished with apt things, so we can clean up a little
apt-get clean

## Thinking that putting the mysql database on the data disk makes
## sense; amazingly it is 2GB on a fresh install!  I think these are
## indices generated using the InnoDB driver
systemctl stop mysql
mv /var/lib/mysql /mnt/data/mysql
ln -s /mnt/data/mysql /var/lib/mysql

echo "alias /var/lib/mysql/ -> /mnt/data/mysql," >> /etc/apparmor.d/tunables/alias
sudo systemctl restart apparmor
systemctl start mysql

# Create database
mysql -u root -p$MYSQL_PASSWORD -e 'show databases;'| grep teamcity > /dev/null
if [ "$?" = "1" ]; then
    cat > /tmp/database-setup.sql <<EOF
CREATE DATABASE $TEAMCITY_DB_NAME DEFAULT CHARACTER SET utf8;
CREATE USER '$TEAMCITY_DB_USER'@'%' IDENTIFIED BY '$TEAMCITY_DB_PASS';
GRANT ALL ON $TEAMCITY_DB_NAME.* TO '$TEAMCITY_DB_USER'@'%';
EOF
    mysql -u root -p$MYSQL_PASSWORD < /tmp/database-setup.sql
    rm /tmp/database-setup.sql
fi

# Setup a user to run the TeamCity server
/usr/sbin/groupadd -r $TEAMCITY_GROUP 2>/dev/null
/usr/sbin/useradd -c $TEAMCITY_USER -r -s /bin/bash -d $TEAMCITY_DIR -g $TEAMCITY_GROUP $TEAMCITY_USER 2>/dev/null

# Download and install TeamCity
if [ ! -d $TEAMCITY_DIR ]; then
    if [ ! -f /vagrant/downloads/$TEAMCITY_TGZ ]; then
        wget --progress=dot:giga --no-proxy $TEAMCITY_URL -P /vagrant/downloads
    fi
    # NOTE: see the comment about the trailing directory of $TEAMCITY_DIR
    tar -zxvf /vagrant/downloads/$TEAMCITY_TGZ -C /opt
fi

# Set up the data directory
if [ ! -f $TEAMCITY_DIR/conf/teamcity-startup.properties ]; then
    echo "teamcity.data.path=$TEAMCITY_DATA_DIR" > \
         $TEAMCITY_DIR/conf/teamcity-startup.properties
fi

mkdir -p /mnt/data/teamcity
ln -s /mnt/data/teamcity $TEAMCITY_DATA_DIR

# Install MySQL JDBC driver
if [ ! -d $TEAMCITY_DIR/shared/lib/jdbc ]; then
    if [ ! -f /vagrant/downloads/$MYSQL_JDBC_JAR ]; then
        wget --no-proxy $MYSQL_JDBC_URL -O /vagrant/downloads/$MYSQL_JDBC_JAR
    fi
    mkdir -p $TEAMCITY_DATA_DIR/lib/jdbc
    cp /vagrant/downloads/$MYSQL_JDBC_JAR $TEAMCITY_DATA_DIR/lib/jdbc
fi

# Configure teamcity to use the mysql database.  This is currently
# done with mustache https://github.com/tests-always-included/mo
mkdir -p $TEAMCITY_DATA_DIR/config

set +x
. /vagrant/scripts/mo
mo /vagrant/files/server/database.mysql.properties.dist > \
   $TEAMCITY_DATABASE_PROPERTIES
set -x

# We might restore an existing database
if [ -f $TEAMCITY_BACKUP ]; then
    # NOTE: this is going to need further work if the database
    # configuration has changed between backup and restore; in that
    # case we need to generate a new database.properties file and then
    # use that with the "-T" flag. The rub is that it cannot be put in
    # the config directory because that causes restore to fail
    echo "*** restore file found"
    TMP_DATABASE_PROPERTIES=/tmp/database.properties
    mv $TEAMCITY_DATABASE_PROPERTIES $TMP_DATABASE_PROPERTIES
    $TEAMCITY_DIR/bin/maintainDB.sh \
        restore \
        -A $TEAMCITY_DATA_DIR \
        -F $TEAMCITY_BACKUP \
        -T $TMP_DATABASE_PROPERTIES
    if [ $? -ne 0 ]; then
        echo "*** restore failed"
        exit 1
    fi
    echo "*** restore complete"
else
    echo "no restore"
fi

chown -R $TEAMCITY_USER:$TEAMCITY_GROUP $TEAMCITY_DIR /mnt/data/teamcity

# Install init script to start TeamCity on server boot
cp /vagrant/files/server/teamcity-server /etc/init.d
update-rc.d teamcity-server defaults

/etc/init.d/teamcity-server start

## TODO: add a weekly or monthly file to thin/delete backups
set +x
. /vagrant/scripts/mo
mo /vagrant/files/server/teamcity-backup > \
   /etc/cron.daily/teamcity-backup
set -x
chmod +x /etc/cron.daily/teamcity-backup
