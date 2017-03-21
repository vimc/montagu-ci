#!/usr/bin/env bash

set -x

PACKAGE_LIST=/vagrant/files/agent/dependencies

# All special repositories must be listed first
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update
# Actually run the install
apt-get -y install $(cat $PACKAGE_LIST)
