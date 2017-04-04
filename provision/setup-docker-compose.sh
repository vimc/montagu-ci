#!/bin/sh

set -x

if which -a docker-compose > /dev/null; then
    echo "docker-compose is already installed"
else
    echo "installing docker-compose"
    sudo curl -L \
         "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" \
         -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi
