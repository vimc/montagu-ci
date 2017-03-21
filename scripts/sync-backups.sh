#!/bin/sh

# TODO: This might be better to avoid and prefer a ssh key backup?  I
# already have regular users set up.
if [ ! -f .ssh/config ]; then
    echo "Setting up ssh settings"
    mkdir -p .ssh
    vagrant ssh-config montagu-ci-server > .ssh/config
fi

RESTORE_LATEST=TeamCity_Backup.zip
RESTORE_TEST=montagu-ci-backup.zip
RESTORE_DIR=shared/restore
# relative from the restore directory
BACKUP_DIR=backup
BACKUP_DIR_REL=../../$BACKUP_DIR

mkdir -p $BACKUP_DIR $RESTORE_DIR
rsync -av --rsh="ssh -F ${PWD}/.ssh/config" \
      montagu-ci-server:/opt/TeamCity/data/backup/ $BACKUP_DIR/

LAST_BACKUP=$(ls $BACKUP_DIR | tail -n1)

rm -f $RESTORE_DIR/$RESTORE_LATEST $RESTORE_DIR/$RESTORE_TEST

if [ ! -z $LAST_BACKUP ]; then
    echo "Setting $LAST_BACKUP as current backup"
    ln $BACKUP_DIR_REL/$LAST_BACKUP $RESTORE_DIR/$RESTORE_LATEST
    ln -s $RESTORE_LATEST $RESTORE_DIR/$RESTORE_TEST
else
    echo "No backup exists; not creating link"
fi
