#!/bin/bash
set -e
set -o pipefail

sysroot=out-lnx/sysroot
name=orchid

function clean() {
    docker container rm "${name}"
}

clean 2>/dev/null || true

docker run -i --name "${name}" -v "${PWD}/env/sysroot_.sh:/init" ubuntu:bionic /init
trap clean EXIT

rm -rf "${sysroot}"
mkdir -p "${sysroot}"
docker export "${name}" | tar -C "${sysroot}" --exclude 'dev/*' -xvf-

find "${sysroot}" -lname '/*' -print0 | while read -r -d $'\0' link; do
    temp=(${link//\// })
    temp=${temp[@]//*/..}
    temp=${temp// /\/}
    temp=${temp#../../../}
    temp=${temp}$(readlink "${link}")
    rm -f "${link}"
    ln -svf "${temp}" "${link}"
done
