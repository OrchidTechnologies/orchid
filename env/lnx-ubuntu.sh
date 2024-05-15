#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update

apt-get -y install \
    ubuntu-keyring \
    bc tcl xxd \
    curl git-core rsync wget \
    fakeroot libtalloc-dev \
    cpio rpm unzip zstd \
    clang clang-tidy lld llvm \
    binutils-{x86-64,aarch64}-linux-gnu \
    binutils-mingw-w64-{i686,x86-64} \
    libc++-dev libc++abi-dev \
    python3-pip python3-setuptools \
    openjdk-11-jre-headless \
    bison flex gperf \
    gettext groff texinfo \
    autoconf autoconf-archive automake \
    libtool meson ninja-build pkg-config \
    qemu-system-{x86,arm} \
