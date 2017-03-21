#!/bin/sh
set -x
if [ ! -f /vagrant/registry/certs/domain.crt ]; then
    echo "Certificate does not exist"
    exit 1
fi
CERT_DEST=/etc/docker/certs.d/fi--didelx05.dide.ic.ac.uk:5000
mkdir -p $CERT_DEST
cp /vagrant/registry/certs/domain.crt
