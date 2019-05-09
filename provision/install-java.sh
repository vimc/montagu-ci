#!/bin/sh

set -ex
JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

if [ -d $JAVA_HOME ]; then
    echo "Java is already installed"
    exit 0
fi

add-apt-repository -y ppa:openjdk-r/ppa
apt-get update
apt-get install -q -y openjdk-8-jdk
