#!/bin/sh
if [ ! -f .ssh/config ]; then
    echo "Setting up ssh settings"
    mkdir -p .ssh
    vagrant ssh-config montagu-ci-server > .ssh/config
fi

mkdir -p backup restore
rsync -av --rsh="ssh -F ${PWD}/.ssh/config" \
      montagu-ci-server:/opt/TeamCity/data/backup/ backup/

LAST_BACKUP=$(ls backup | tail -n1)
RESTORE=restore/TeamCity_Backup.zip
rm -f $RESTORE

if [ ! -z $LAST_BACKUP ]; then
    echo "Setting $LAST_BACKUP as current backup"
    ln -s ../backup/$LAST_BACKUP $RESTORE
else
    echo "No backup exists; not creating link"
fi
