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

if getent passwd teamcity > /dev/null; then
    if id -Gn teamcity | grep -qv "\bdocker\b"; then
        echo "Adding teamcity to the docker group"
        usermod -aG docker teamcity
    fi
fi
