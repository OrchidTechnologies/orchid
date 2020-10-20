#!/bin/bash
set -e
set -o pipefail

sysroot=$1
distro=$2
shift 2

name=orchid

docker rm -f "env-${name}" &>/dev/null || true
docker run -i --name "env-${name}" -v "${PWD}/env:/mnt" ubuntu:"${distro}" /mnt/setup-sys.sh "$@"

rm -rf "${sysroot}"
mkdir -p "${sysroot}"
pushd "${sysroot}"

docker export "env-${name}" | fakeroot tar --exclude dev -xmvf-

popd
env/relink.sh "${sysroot}"
