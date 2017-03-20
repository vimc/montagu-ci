#!/bin/sh
apt-get update
# This avoids an issue with grub-pc in the bento ubuntu box:
#
# https://github.com/chef/bento/issues/661#issuecomment-248136601
DEBIAN_FRONTEND=noninteractive apt-get -y \
               -o Dpkg::Options::="--force-confdef" \
               -o Dpkg::Options::="--force-confold" \
               upgrade
