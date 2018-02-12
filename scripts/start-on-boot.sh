#!/usr/bin/env bash
set -ex
here=$(dirname $(dirname $(realpath $0)))
target=/etc/systemd/system/montagu-ci.service
read -p "What user should vagrant run as? " user

set -ex
cp $here/scripts/montagu-ci.service $target
sed -i "s:__PATH__:$here:g" $target
sed -i "s:__USER__:$user:g" $target
systemctl enable montagu-ci

set +x
echo ""
echo "Montagu continuous integration is installed as a service as user $user" 
echo "and will automatically resume after a system boot. To start the VMs now," 
echo "run:"
echo ""
echo "systemctl start montagu-ci"
echo ""
