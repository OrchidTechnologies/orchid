#!/bin/bash
set -e

pacman -Sy \
    ubuntu-keyring \
    bc sed tcl vim \
    curl git rsync wget \
    fakeroot talloc \
    cpio rpm-tools unzip zstd \
    clang lld llvm \
    binutils aarch64-linux-gnu-binutils \
    mingw-w64-binutils \
    libc++ libc++abi \
    python-{packaging,pip,setuptools} \
    jdk17-openjdk \
    bison flex gperf \
    gettext groff texinfo \
    autoconf{,-archive} automake libtool \
    make ninja pkgconf \
    cmake meson \
    qemu-system-{x86,aarch64} \
