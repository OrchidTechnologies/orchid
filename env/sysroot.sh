#!/bin/bash
set -e
set -o pipefail

docker container rm orchid || true
docker run -i --name orchid -v "${PWD}/env/setup.sh:/setup.sh" ubuntu:bionic /setup.sh

sysroot=out-lnx/sysroot
rm -rf "${sysroot}"
mkdir -p "${sysroot}"

docker export orchid | tar -C "${sysroot}" --exclude 'dev/*' -xvf-

find "${sysroot}" -lname '/*' -print0 | while read -r -d $'\0' link; do
    temp=(${link//\// })
    temp=${temp[@]//*/..}
    temp=${temp// /\/}
    temp=${temp#../../../}
    temp=${temp}$(readlink "${link}")
    rm -f "${link}"
    ln -svf "${temp}" "${link}"
done
