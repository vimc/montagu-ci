#!/bin/sh
CERT_COMMONNAME="fi--didelx05.dide.ic.ac.uk"
CERT_COUNTRY="UK"
CERT_STATE="London"
CERT_LOCALITY="London"
CERT_ORGANIZATION="Imperial"
CERT_ORGANIZATIONALUNIT="DIDE"
CERT_EMAIL="r.fitzjohn@imperial.ac.uk"
CERT_SUBJ="/C=$CERT_COUNTRY/ST=$CERT_STATE/L=$CERT_LOCALITY/O=$CERT_ORGANIZATION/OU=$CERT_ORGANIZATIONALUNIT/CN=$CERT_COMMONNAME/emailAddress=$CERT_EMAIL"

if [ -f certs/domain.key ] || [ -f certs/domain.crt ]; then
    echo "Key already exists; please delete if you want to create a new key"
    exit 1
fi

mkdir -p certs
openssl req \
        -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key \
        -x509 -days 365 -out certs/domain.crt \
        -subj $CERT_SUBJ
SUCCESS=$?
if [ $SUCCESS -eq 0 ]; then
    if [ -d ../shared/files/agent ]; then
        echo "Copying certificate to vagrant shared directory"
        cp certs/domain.crt ../shared/files/agent/registry.crt
    fi
fi
exit $SUCCESS
