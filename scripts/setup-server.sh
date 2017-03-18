#!/bin/sh

set -x
exit 0

MYSQL_PASSWORD=admin

TEAMCITY_DB_HOST=localhost
TEAMCITY_DB_NAME=teamcity
TEAMCITY_DB_USER=teamcity
TEAMCITY_DB_PASS=teamcity
TEAMCITY_USER=teamcity
TEAMCITY_GROUP=teamcity

MYSQL_JDBC_VERS=5.1.34
MYSQL_JDBC_JAR=mysql-connector-java-${MYSQL_JDBC_VERS}.jar
MYSQL_JDBC_URL=http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/${MYSQL_JDBC_VERS}/${MYSQL_JDBC_JAR}

# NOTE: this is based around the name of the top level directory in
# the TGZ; if it ever changes this will fail.
TEAMCITY_VERSION=10.0.5
TEAMCITY_DIR=/opt/TeamCity
TEAMCITY_TGZ=TeamCity-${TEAMCITY_VERSION}.tar.gz
TEAMCITY_URL=http://download.jetbrains.com/teamcity/$TEAMCITY_TGZ

# Install various packages required to run TeamCity
apt-get update
apt-get install -y unzip

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

# Create database
mysql -u root -p$MYSQL_PASSWORD -e 'show databases;'| grep teamcity > /dev/null
if [ "$?" = "1" ]; then
    cat > /tmp/database-setup.sql <<EOF
CREATE DATABASE $TEAMCITY_DB_NAME DEFAULT CHARACTER SET utf8;

CREATE USER '$TEAMCITY_DB_USER'@'%' IDENTIFIED BY '$TEAMCITY_DB_PASS';
GRANT ALL ON $TEAMCITY_DB_NAME.* TO '$TEAMCITY_DB_USER'@'%';
EOF
# flush privileges;
    mysql -u root -p$MYSQL_PASSWORD < /tmp/database-setup.sql
    rm /tmp/database-setup.sql
fi

# Setup a user to run the TeamCity server
/usr/sbin/groupadd -r $TEAMCITY_GROUP 2>/dev/null
/usr/sbin/useradd -c $TEAMCITY_USER -r -s /bin/bash -d $TEAMCITY_DIR -g $TEAMCITY_GROUP $TEAMCITY_USER 2>/dev/null

# Download and install TeamCity
if [ ! -f $TEAMCITY_DIR ]; then
    if [ ! -f /vagrant/downloads/$TEAMCITY_TGZ ]; then
        wget --no-proxy $TEAMCITY_URL -P /vagrant/downloads
    fi
    tar -zxvf /vagrant/downloads/$TEAMCITY_TGZ -C /opt
    cp /vagrant/downloads/$TEAMCITY_TGZ $TEAMCITY_DIR
fi

# Install MySQL JDBC driver
if [ ! -d $TEAMCITY_DIR/shared/lib ]; then
    if [ ! -f /vagrant/downloads/$MYSQL_JDBC_JAR ]; then
        wget --no-proxy $MYSQL_JDBC_URL -O /vagrant/downloads/$MYSQL_JDBC_JAR
    fi
    mkdir -p $TEAMCITY_DIR/data/lib/jdbc
    cp /vagrant/downloads/$MYSQL_JDBC_JAR $TEAMCITY_DIR/data/lib/jdbc
fi

# Configure teamcity to use the mysql database.  This is currently
# done with mustache https://github.com/tests-always-included/mo
mkdir -p $TEAMCITY_DIR/data/config
. /vagrant/scripts/mo
mo /vagrant/files/server/database.mysql.properties.dist > \
   $TEAMCITY_DIR/data/config/database.properties

chown -R $TEAMCITY_USER:$TEAMCITY_GROUP $TEAMCITY_DIR

# Install init script to start TeamCity on server boot
cp /vagrant/files/server/teamcity-server /etc/init.d
update-rc.d teamcity-server defaults
/etc/init.d/teamcity-server start
