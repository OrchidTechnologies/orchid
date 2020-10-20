#!/bin/bash
set -e
. env/cwd.sh

version=$1
output=$2
source=$3
shift 3

flags=()
if [[ ${output} != - ]]; then
    flags+=(-o /mnt/"${PWD##*/}"/"${output}")
fi

exec docker run -v "${cwd%/*}":/mnt ethereum/solc:"${version}" \
    "${flags[@]}" /mnt/"${PWD##*/}"/"${source}" \
    --bin --overwrite --allow-paths . "$@"
