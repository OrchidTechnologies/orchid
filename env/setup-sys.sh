#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get -y update
apt-get -y dist-upgrade
apt-get -y install libstdc++-5-dev{,-arm64-cross} "$@"
ln -s .. usr/aarch64-linux-gnu/usr
