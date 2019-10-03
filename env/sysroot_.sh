#!/bin/bash
set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get -y dist-upgrade

apt-get -y install software-properties-common wget apt-transport-https
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
apt-add-repository 'deb https://apt.llvm.org/trusty/ llvm-toolchain-trusty-8 main'
apt-get update

apt-get -y install libgcc-4.8-dev libc++abi-8-dev libc++-8-dev

#apt-get -y install rsync
#rsync -SPaxz --include '*.a' --include '*.h' --include '*.so' / /mnt
