#!/usr/bin/env bash

set -x

TEAMCITY_DIR=/opt/teamcity-agent
TEAMCITY_USER=teamcity
TEAMCITY_GROUP=teamcity
TEAMCITY_SERVER_ROOT="http://teamcity:8111/"
AGENT_NAME=`hostname -s`

if [ -d $TEAMCITY_DIR ]; then
    echo "Agent is already provisioned"
    exit 0
fi

# Install various packages required to run a TeamCity Build Agent
apt-get update
apt-get install -y unzip

# Setup a user to run the TeamCity agent
/usr/sbin/groupadd -r $TEAMCITY_GROUP 2>/dev/null
/usr/sbin/useradd -c $TEAMCITY_USER -r -s /bin/bash -d $TEAMCITY_DIR -g $TEAMCITY_GROUP $TEAMCITY_USER 2>/dev/null

cat >> /etc/hosts <<EOF
192.168.80.10   teamcity.localdomain teamcity
EOF

# Download Build Agent from server and install
wget -q --no-proxy \
     ${TEAMCITY_SERVER_ROOT}/update/buildAgent.zip -O /tmp/buildAgent.zip
mkdir -p $TEAMCITY_DIR
unzip -q /tmp/buildAgent.zip -d $TEAMCITY_DIR

set +x
. /vagrant/bin/mo
mo /vagrant/files/agent/buildAgent.dist.properties > \
   $TEAMCITY_DIR/conf/buildAgent.properties
set -x

chown -R $TEAMCITY_USER:$TEAMCITY_GROUP $TEAMCITY_DIR

if [ ! -f /etc/init.d/teamcity-agent ]; then
    cp /vagrant/files/agent/teamcity-agent /etc/init.d
    update-rc.d teamcity-agent defaults
fi
/etc/init.d/teamcity-agent start
