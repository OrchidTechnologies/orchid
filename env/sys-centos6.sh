#!/bin/bash
set -e
set -o pipefail

sysroot=$1
machine=$2
arch=$3
shift 3

rm -rf "${sysroot}"
mkdir -p "${sysroot}"
pushd "${sysroot}"

#vault=https://vault.centos.org
vault=https://archive.kernel.org/centos-vault
#vault=http://linuxsoft.cern.ch/centos-vault
#vault=http://mirror.nsc.liu.se/centos-store

function rpm() {
    curl -s "${vault}"/6.0/os/"${machine}"/Packages/"$1".el6."${arch}".rpm | rpm2cpio - | cpio -i
    find . -type d ! -perm 755 -exec chmod 755 {} +
}

rpm filesystem-2.4.30-2.1
rpm kernel-headers-2.6.32-71
rpm glibc-2.12-1.7
rpm glibc-headers-2.12-1.7
rpm glibc-devel-2.12-1.7
rpm glibc-static-2.12-1.7
rpm libgcc-4.4.4-13
rpm gcc-4.4.4-13
rpm libstdc++-devel-4.4.4-13

popd
env/relink.sh "${sysroot}"
