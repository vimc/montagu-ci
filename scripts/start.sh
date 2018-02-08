#!/usr/bin/env bash
set -e
vagrant plugin install vagrant-persistent-storage
if [[ -z $(vagrant box list | grep bento/ubuntu-16.04) ]]; then
	vagrant box add --provider=virtualbox \
		bento/ubuntu-16.04 https://app.vagrantup.com/bento/boxes/ubuntu-16.04
fi
vagrant up montagu-ci-server
vagrant up
vagrant status
