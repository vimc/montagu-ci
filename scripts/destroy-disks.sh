#!/usr/bin/env bash
echo "*** checking vagrant status"
if grep running <(vagrant status); then
    echo "vagrant running: can't delete disks"
    exit 1
else
    echo "vagrant not running: deleting disks"
fi

for f in `ls disk/*.vdi`; do
    echo "Removing $f"
    vboxmanage closemedium disk disk/$f --delete
done
