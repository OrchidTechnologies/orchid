#!/bin/bash
set -e
if [[ $(autom4te --version | head -n 1) == "autom4te (GNU Autoconf) 2.69" ]]; then
    ./autogen.sh
else
    docker run --rm -i -v "${PWD}/../env/autogen_.sh:/init" -v "${PWD}:/mnt" ubuntu:bionic /init
fi
