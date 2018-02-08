#!/bin/sh

set -x

VERSION=1.19.0

if which -a docker-compose > /dev/null; then
    echo "docker-compose is already installed"
else
    echo "installing docker-compose"
    sudo curl -L \
         "https://github.com/docker/compose/releases/download/$VERSION/docker-compose-$(uname -s)-$(uname -m)" \
         -o /usr/bin/docker-compose
    sudo chmod +x /usr/bin/docker-compose
fi
