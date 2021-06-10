#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get -y update
apt-get -y dist-upgrade
apt-get -y install libstdc++-5-dev{,-arm{el,hf,64}-cross} "$@"
for root in usr/*-gnu*; do
    ln -s .. "${root}"/usr
done
