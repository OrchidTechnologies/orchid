#!/bin/bash
set -e
apt-get update
apt-get -y install autoconf libtool
cd /mnt
# XXX: run autogen__.sh
NOCONFIGURE=1 ./autogen.sh
