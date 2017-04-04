#!/usr/bin/env bash
REGISTRY_NAME=registry
RUNNING=$(docker inspect --format="{{.State.Running}}" $REGISTRY_NAME 2> \
                 /dev/null)
PATH_KEY=certs/domain.key
PATH_CRT=certs/domain.crt

if [[ "$RUNNING" == "true" ]]; then
    echo "Registry already running"
    exit 0
fi

if [ ! -f "$PATH_KEY" ]; then
    echo "Key not found at $PATH_KEY"
    exit 1
fi
if [ ! -f "$PATH_CRT" ]; then
    echo "Certificate not found at $PATH_CRT"
    exit 1
fi

echo "Starting docker registry"
docker run -d -p 5000:5000 --restart=always --name registry \
       -v `pwd`/certs:/certs \
       -v registry_data:/var/lib/registry \
       -e REGISTRY_HTTP_TLS_CERTIFICATE=$PATH_CRT \
       -e REGISTRY_HTTP_TLS_KEY=$PATH_KEY \
       registry:2
exit $?
