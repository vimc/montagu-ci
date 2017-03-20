#!/bin/sh

set -x
JAVA_HOME=/usr/lib/jvm/java-8-oracle
JAVA_CACHE_VAGRANT=/vagrant/downloads/java
JAVA_CACHE_SYSTEM=/var/cache/oracle-jdk8-installer

if [ -d $JAVA_HOME ]; then
    echo "Java is already installed"
    exit 0
fi

if [ -d $JAVA_CACHE_VAGRANT ]; then
    rsync -av $JAVA_CACHE_VAGRANT/ `dirname $JAVA_CACHE_SYSTEM`
fi

add-apt-repository -y ppa:webupd8team/java
apt-get update
echo debconf shared/accepted-oracle-license-v1-1 select true | \
    debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | \
    debconf-set-selections
apt-get install -q -y oracle-java8-installer

rsync -av $JAVA_CACHE_SYSTEM $JAVA_CACHE_VAGRANT
rm -r $JAVA_CACHE_SYSTEM
