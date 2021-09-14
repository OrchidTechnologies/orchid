#!/bin/bash
set -e

which sudo &>/dev/null || function sudo() {
    [[ "$1" == -EH ]]
    shift
    "$@"
}

export DEBIAN_FRONTEND=noninteractive
sudo -EH apt-get update

sudo -EH apt-get -y install \
    bc curl git-core rsync tcl vim-common \
    capnproto cpio rpm unzip zstd \
    clang clang-tidy lld \
    libc++-dev libc++abi-dev \
    g++-multilib gcc-multilib \
    python python3-pip python3-setuptools \
    bison flex gperf \
    gettext groff texinfo \
    autoconf autoconf-archive automake libtool \
    ninja-build pkg-config \

function usable() {
    # Ubuntu bionic ships meson 0.45, which is too old to build glib
    # XXX: consider checking for meson 0.52 (it broke cross linking)

    # Ubuntu focal ships meson 0.53, which is still incompatible with the lld that comes in the r22 Android NDK
    # meson passes --allow-shlib-undefined to lld, which only recently added it https://reviews.llvm.org/D57385
    # this bug is now fixed in meson, but also not until recently https://github.com/mesonbuild/meson/pull/5912

    for version in $(apt-cache show meson | sed -e '/^Version: */!d;s///'); do
        if dpkg --compare-versions "${version}" ">=" "0.54.0"; then
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
