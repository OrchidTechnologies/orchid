#!/bin/bash
set -e
set -o pipefail

sysroot=out-lnx/sysroot
name=orchid

function clean() {
    docker container rm "${name}"
}

clean 2>/dev/null || true

docker run -i --name "${name}" -v "${PWD}/env/sysroot_.sh:/init" ubuntu:xenial /init
trap clean EXIT

env/export.sh "${name}" "${sysroot}"
