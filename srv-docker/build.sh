#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install git-core

cd /usr/src
git clone "$1"
cd orchid
git checkout "$2"
git submodule update --init --recursive --jobs 3

env/setup-dkr.sh make -j3 -C srv-shared install debug=crossndk usr=/usr
cp -a srv-shared/out-lnx/x86_64/orchidd /mnt/orchidd
