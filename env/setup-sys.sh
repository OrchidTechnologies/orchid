#!/bin/bash
set -e
llvm=$1
shift 1
export DEBIAN_FRONTEND=noninteractive
apt-get -y update
apt-get -y dist-upgrade
apt-get -y install --no-install-recommends libstdc++-"${llvm}"-dev{,-{arm{hf,64},i386}-cross} "$@"
for root in /usr/*-gnu*; do
    ln -s .. "${root}"/usr
done
