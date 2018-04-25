#!/usr/bin/env bash

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# TODO: This might be better to avoid and prefer a ssh key backup?  I
# already have regular users set up.
if [ ! -f .ssh/config ]; then
    echo "Setting up ssh settings"
    mkdir -p .ssh
    sudo -EH -u vagrant vagrant ssh-config montagu-ci-server > .ssh/config
    sudo chown -R vagrant.vagrant .ssh
fi

RESTORE_LATEST=TeamCity_Backup.zip
RESTORE_DIR=shared/restore
# relative from the restore directory
BACKUP_DIR=/montagu/teamcity

mkdir -p $BACKUP_DIR $RESTORE_DIR
rsync -av --rsh="ssh -F ${PWD}/.ssh/config" \
      montagu-ci-server:/opt/TeamCity/data/backup/ $BACKUP_DIR/

LAST_BACKUP=$(ls $BACKUP_DIR | tail -n1)

rm -f $RESTORE_DIR/$RESTORE_LATEST

if [ ! -z $LAST_BACKUP ]; then
    echo "Setting $LAST_BACKUP as current backup"
    cp $BACKUP_DIR/$LAST_BACKUP $RESTORE_DIR/$RESTORE_LATEST
else
    echo "No backup exists; not creating link"
fi
