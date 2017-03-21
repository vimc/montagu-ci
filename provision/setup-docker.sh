#!/bin/sh

set -x

if which -a docker > /dev/null; then
    echo "docker is already installed"
else
    echo "installing docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
         "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
    apt-get update
    apt-get install -y docker-ce
fi

REGISTRY_HOST=fi--didelx05.dide.ic.ac.uk:5000
CERT_DEST=/etc/docker/certs.d/$REGISTRY_HOST
CERT_SRC=/vagrant/files/agent/registry.crt

if [ ! -f $CERT_SRC ]; then
    echo "Certificate does not exist; see README, section 'docker registry'"
    exit 1
fi

mkdir -p $CERT_DEST
cp $CERT_SRC $CERT_DEST/domain.crt
exit $?
