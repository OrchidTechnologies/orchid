#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update

apt-get -y install \
    ubuntu-keyring \
    bc sed tcl xxd \
    curl git-core rsync wget \
    fakeroot libtalloc-dev \
    cpio rpm unzip zstd \
    clang clang-tidy lld llvm \
    binutils-{x86-64,aarch64}-linux-gnu \
    binutils-mingw-w64-{i686,x86-64} \
    libc++-dev libc++abi-dev \
    python3-{packaging,pip,setuptools} \
    openjdk-17-jdk-headless \
    bison flex gperf \
    gettext groff texinfo \
    autoconf{,-archive} automake libtool \
    make ninja-build pkg-config \
    cmake meson \
    qemu-system-{x86,arm} \

if dpkg --compare-versions $(meson --version) '<<' "1.2.0"; then
    pip3 install --upgrade meson
fi
