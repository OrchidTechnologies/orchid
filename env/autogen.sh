#!/bin/bash
set -e
src=$1
shift
if [[ $(autom4te --version | head -n 1) == "autom4te (GNU Autoconf) 2.69" ]]; then
    unset MAKEFLAGS
    unset MFLAGS
    exec env/autogen__.sh "${src}" "$@"
else
    exec docker run --rm -i -v "${PWD}/env/autogen_.sh:/init" -v "${PWD}/${src}:/mnt" ubuntu:bionic /init "$@"
fi
