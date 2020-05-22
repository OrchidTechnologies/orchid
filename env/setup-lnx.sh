#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
sudo -EH apt-get -y install autoconf bc bison cpio capnproto flex gettext gperf groff libtool ninja-build python python3-pip python3-setuptools rpm tcl texinfo
sudo -EH apt-get -y install clang-9 libc++-9-dev libc++abi-9-dev clang-tidy-9
sudo -EH pip3 install meson

env/setup-all.sh
