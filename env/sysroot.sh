#!/bin/bash
set -e
set -o pipefail

sysroot=$1
shift 1

name=orchid

function clean() {
    docker container rm "${name}"
}

clean 2>/dev/null || true

docker run -i --name "${name}" -v "${PWD}/env/sysroot_.sh:/init" centos:6 /init
trap clean EXIT

env/export.sh "${name}" "${sysroot}"
