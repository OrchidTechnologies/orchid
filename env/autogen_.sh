#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install autoconf gettext git-core libtool
cd /mnt
# XXX: run autogen__.sh
NOCONFIGURE=1 ./autogen.sh
