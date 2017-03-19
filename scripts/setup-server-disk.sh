#!/usr/bin/env bash

# To start again and wipe out the disk, in this order:
#
#   wipefs -a /dev/sdb1
#   fdisk /dev/sdb ; d; w

DATA_MOUNT=/mnt/data

mkdir -p $DATA_MOUNT

if [ ! -b /dev/sdb1 ]; then
    echo "Adding partition table to /dev/sdb"
    echo ';' | sfdisk /dev/sdb
else
    echo "Partition table already exists"
fi

if [[ $(file -sL /dev/sdb1 | grep "/dev/sdb1: data$") ]]; then
    echo "Formatting /dev/sdb1"
    mkfs.ext4 /dev/sdb1
else
    echo "Filesystem already exists"
fi

# Now let's get this into the fstab
if [[ ! $(grep "^/dev/sdb1" /etc/fstab) ]]; then
    echo "Adding /dev/sdb1 to fstab"
    echo "/dev/sdb1 ${DATA_MOUNT} ext4 defaults 0 2" >> /etc/fstab
else
    echo "/dev/sdb1 already in fstab"
fi

if [[ ! -d $DATA_MOUNT/lost+found ]]; then
    echo "Mounting /dev/sdb1 to $DATA_MOUNT"
    mount $DATA_MOUNT
else
    echo "/dev/sdb1 already mounted at $DATA_MOUNT"
fi
