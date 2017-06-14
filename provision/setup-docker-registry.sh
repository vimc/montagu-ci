#!/bin/sh

set -x

REGISTRY_HOST=docker.montagu.dide.ic.ac.uk:5000
CERT_DEST=/etc/docker/certs.d/$REGISTRY_HOST
CERT_SRC=/vagrant/files/agent/registry.crt

if [ ! -f $CERT_SRC ]; then
    echo "Certificate does not exist; see README, section 'docker registry'"
    exit 1
fi

mkdir -p $CERT_DEST
cp $CERT_SRC $CERT_DEST/domain.crt
exit $?
