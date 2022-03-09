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

vaults=()
vaults+=(https://vault.centos.org)
vaults+=(https://archive.kernel.org/centos-vault)
#vaults+=(http://linuxsoft.cern.ch/centos-vault)
#vaults+=(http://mirror.nsc.liu.se/centos-store)

function rpm() {
    for vault in "${vaults[@]}"; do
        if curl -s -o "$1".rpm -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36' "${vault}"/6.0/os/"${machine}"/Packages/"$1".el6."${arch}".rpm; then
            rpm2cpio "$1".rpm | cpio -i
            find . -type d ! -perm 755 -exec chmod 755 {} +
            return
        fi
    done
    false
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
