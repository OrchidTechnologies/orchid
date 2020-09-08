#!/bin/bash
set -e
. env/cwd.sh

version=$1
output=$2
source=$3
shift 3

exec docker run -v "${cwd%/*}":/mnt ethereum/solc:"${version}" \
    -o /mnt/"${PWD##*/}"/"${output}" /mnt/"${PWD##*/}"/"${source}" \
    --bin --overwrite --allow-paths . "$@"
