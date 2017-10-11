#!/bin/sh
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
