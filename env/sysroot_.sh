#!/bin/bash
set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
#apt-get -y dist-upgrade

apt-get -y install software-properties-common wget
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
apt-add-repository 'deb https://apt.llvm.org/bionic/ llvm-toolchain-bionic-8 main'

apt-get -y install libgcc-7-dev libc++abi-8-dev libc++-8-dev

#apt-get -y install rsync
#rsync -SPaxz --include '*.a' --include '*.h' --include '*.so' / /mnt
