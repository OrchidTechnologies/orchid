#!/bin/bash
set -e
apt-get update
apt-get -y install autoconf libtool
cd /mnt
./autogen.sh
