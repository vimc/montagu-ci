#!/usr/bin/env bash
set -ex
systemctl disable montagu-ci.service
rm /etc/systemd/system/montagu-ci.service
echo "Done"
