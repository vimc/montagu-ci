#!/bin/sh
set -e

# The scripts/sync-backups.sh script must be run from the montagu-ci
# directory because the backups will be accessed via the
# montagu-ci/shared directory.  So before running the task we first
# change to here and then run the script.  The construction below:
#
# 1. checks that the working directory is probably the right directory
#    to run the sync script from
#
# 2. capture the absolute path to the working directory (as
#    PATH_VAGRANT to avoid ambiguity about where the special variable
#    PWD is referenced)
#
# 3. writes out the cron script including this path
if [ ! -f scripts/sync-backups.sh ]; then
    echo "Run this from the montagu-ci directory"
    exit 1
fi

PATH_VAGRANT=$PWD
DEST=/etc/cron.daily/teamcity-backup-sync

cat <<EOF > $DEST
#!/bin/sh
cd ${PATH_VAGRANT} && ./scripts/sync-backups.sh
EOF
chmod +x $DEST
