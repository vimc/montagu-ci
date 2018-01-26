#!/usr/bin/env bash
set -ex
here=$(dirname $(dirname $(realpath $0)))
target=/etc/systemd/system/montagu-ci.service

cp $here/scripts/montagu-ci.service $target
sed -i "s:__PATH__:$here:g" $target
sed -i "s:__USER__:$USER:g" $target
systemctl enable montagu-ci
