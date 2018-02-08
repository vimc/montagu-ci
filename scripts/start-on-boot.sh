#!/usr/bin/env bash
set -ex
here=$(dirname $(dirname $(realpath $0)))
target=/etc/systemd/system/montagu-ci.service
user=$USER

sudo -s <<EOF
	set -ex
	cp $here/scripts/montagu-ci.service $target
	sed -i "s:__PATH__:$here:g" $target
	sed -i "s:__USER__:$user:g" $target
	systemctl enable montagu-ci
	systemctl start montagu-ci
EOF

set +x
echo "Montagu continuous integration should now be running and accessible"
echo "at port 8111, and should automatically resume after a system boot."
echo "The service is running as $user."
