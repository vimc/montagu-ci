#!/usr/bin/env bash
set -e
vagrant plugin install vagrant-persistent-storage
vagrant up montagu-ci-server
vagrant up
