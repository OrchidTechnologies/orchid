#!/bin/bash
set -e
set -o pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y dist-upgrade
apt -y install software-properties-common wget
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
apt-add-repository 'deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-8 main'
apt -y install clang-8 libc++-8-dev libc++abi-8-dev
