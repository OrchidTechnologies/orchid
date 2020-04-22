#!/bin/bash
set -e
set -o pipefail

name=$1
sysroot=$2
shift 2

rm -rf "${sysroot}"
mkdir -p "${sysroot}"
cd "${sysroot}"

docker export "${name}" | fakeroot tar --exclude dev -xmvf- "$@"

find . -type d ! -perm 755 -exec chmod 755 {} +

find . -lname '/*' -print0 | while read -r -d $'\0' link; do
    temp=(${link//\// })
    temp=${temp[@]//*/..}
    temp=${temp// /\/}
    temp=${temp#../../}
    temp=${temp}$(readlink "${link}")
    rm -f "${link}"
    ln -svf "${temp}" "${link}"
done
