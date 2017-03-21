#!/usr/bin/env bash

set -x

PACKAGE_LIST=/vagrant/files/agent/dependencies

# All special repositories must be listed first
apt-get update
# Actually run the install
apt-get -y install $(cat $PACKAGE_LIST)
