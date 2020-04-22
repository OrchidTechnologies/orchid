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

docker run -i --name "${name}" centos:6 yum -y install gcc-c++
trap clean EXIT

env/export.sh "${name}" "${sysroot}" \
    --exclude etc \
    --exclude usr/lib/locale \
    --exclude usr/lib/python2.6 \
    --exclude usr/lib64/python2.6 \
    --exclude usr/share \
    --exclude var \
