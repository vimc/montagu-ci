#!/usr/bin/env bash

set -x

RESTART_SSH=1
if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
    if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
        echo "password login already disabled"
        RESTART_SSH=0
    else
        echo "disabling password login"
        sed -i'' "/^[^#]*PasswordAuthentication[[:space:]]yes/c\PasswordAuthentication no" /etc/ssh/sshd_config
    fi
else
    echo "preventing password login"
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
fi

if [ $RESTART_SSH -eq 1 ]; then
    echo "Restarting ssh"
    service ssh restart
fi

NEW_USERS=$(ls /vagrant/files/keys | sed 's/.pub$//')
NEW_PASS=horsestaple

for NEW_USER in $NEW_USERS; do
    getent passwd $NEW_USER > /dev/null 2&>1
    RES=$?
    if [ $RES -eq 0 ]; then
        echo "User $NEW_USER already exists"
    else
        echo "Adding user $NEW_USER"
        sudo /usr/sbin/useradd -m -p $(openssl passwd -1 $NEW_PASS) $NEW_USER
        mkdir -p /home/$NEW_USER/.ssh
        cp /vagrant/files/keys/$NEW_USER.pub \
           /home/$NEW_USER/.ssh/authorized_keys
        chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
        usermod -aG sudo $NEW_USER
    fi
done
