#!/usr/bin/env bash

set -x

# This must agree with the three lines in setup-agent.sh
TEAMCITY_DIR=/opt/teamcity-agent
TEAMCITY_USER=teamcity
TEAMCITY_GROUP=teamcity
/usr/sbin/groupadd -r $TEAMCITY_GROUP 2>/dev/null
/usr/sbin/useradd -c $TEAMCITY_USER -r -s /bin/bash -d $TEAMCITY_DIR -g $TEAMCITY_GROUP $TEAMCITY_USER 2>/dev/null

# This grants the teamcity group permission to restart Docker
# via sudo without needing a password. This is needed for the
# Montagu repo build, which restarts the Docker daemon to simulate
# a reboot.
echo "%teamcity ALL=NOPASSWD: /bin/systemctl restart docker" \
	| sudo tee /etc/sudoers.d/teamcity
