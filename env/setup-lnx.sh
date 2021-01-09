#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

sudo -EH apt-get -y install \
    bc cpio capnproto rpm tcl vim-common zstd \
    clang clang-tidy lld \
    libc++-dev libc++abi-dev \
    python python3-pip python3-setuptools \
    bison flex gperf \
    gettext groff texinfo \
    autoconf automake libtool \
    ninja-build pkg-config \

function usable() {
    # Ubuntu bionic ships meson 0.45, which is too old to build glib
    # XXX: consider checking for meson 0.52 (it broke cross linking)
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
