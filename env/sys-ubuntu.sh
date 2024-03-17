#!/bin/bash
set -e
set -o pipefail

sysroot=$1
distro=$2
shift 2

mount=${PWD}/env

rm -rf "${sysroot}"
mkdir -p "${sysroot}"
pushd "${sysroot}"

# docker does not work inside of docker. proot apt/dpkg only works on Linux
# XXX: this is only barely deterministic. it doesn't even have a lock file!
# debootstrap (with --include instead of setup-sys) might be cross-platform
# or maybe reimplement using multistrap? https://wiki.debian.org/Multistrap

if [[ $(uname -s) = Linux ]]; then
    # older versions of proot can't handle newer versions of glibc
    flock "${mount}/proot.lock" "${MAKE:=make}" -C "${mount}/proot/src" PYTHON=false
    proot=${mount}/proot/src/proot

    debootstrap=${mount}/debootstrap
    # XXX: proot -0 runs the command but fails on exit; fakeroot works correctly
    DEBOOTSTRAP_DIR=${debootstrap} fakeroot "${debootstrap}"/debootstrap --foreign \
        --variant=minbase --arch amd64 --components=main,universe "${distro}" .

    "${proot}" -0 -r . -w / -b /proc -b /sys /debootstrap/debootstrap --second-stage
    # XXX: https://groups.google.com/g/linux.debian.bugs.dist/c/-p06sQmwamA
    echo "deb http://archive.ubuntu.com/ubuntu/ ${distro}-updates main universe" >>etc/apt/sources.list
    HOME= "${proot}" -S . -w / -b "${mount}:/mnt" /mnt/setup-sys.sh "$@"
else
    # https://stackoverflow.com/questions/29934204/mount-data-volume-to-docker-with-readwrite-permission
    if [[ -d /tmp/lima ]]; then
        tarball=/tmp/lima/export-$$.tgz
    else
        tarball=${PWD}/export.tgz
    fi

    touch "${tarball}"
    clean() { rm -f "${tarball}"; }
    trap clean EXIT

    ${ENV_DOCKER:=docker} run --platform linux/amd64 -i --rm \
        -v "${mount}:/mnt" -v "${tarball}:/tmp/export.tgz" \
        ubuntu:"${distro}" /mnt/export.sh /mnt/setup-sys.sh "$@"
    fakeroot tar --exclude dev -vxzmf "${tarball}"
fi

popd
env/relink.sh "${sysroot}"
