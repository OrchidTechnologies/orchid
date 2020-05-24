#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
sudo -EH apt-get -y install autoconf bc bison cpio capnproto flex gettext gperf groff libtool ninja-build python python3-pip python3-setuptools rpm tcl texinfo
sudo -EH apt-get -y install clang-9 libc++-9-dev libc++abi-9-dev clang-tidy-9

function usable() {
    # Ubuntu bionic ships meson 0.45, which is too old to build glib
    for version in $(apt-cache show meson | sed -e '/^Version: */!d;s///'); do
        if dpkg --compare-versions "${version}" ">=" "0.48.0"; then
            return
        fi
    done
false; }

if usable; then
    sudo -EH apt-get -y install meson
else
    sudo -EH pip3 install meson
fi

env/setup-all.sh
