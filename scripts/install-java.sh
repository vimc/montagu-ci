#!/bin/sh
echo "Installing Java"
set -x
export JAVA_HOME=/usr/lib/jvm/java-8-oracle

if [ ! -d $JAVA_HOME ]; then
    add-apt-repository -y ppa:webupd8team/java
    apt-get update
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
    apt-get install -y oracle-java8-installer
fi
