#!/bin/bash
set -e
if [[ $(autom4te --version | head -n 1) == "autom4te (GNU Autoconf) 2.69" ]]; then
    unset MAKEFLAGS
    unset MFLAGS
    exec env/autogen__.sh "$@"
else
    exec docker run --rm -i -v "${PWD%/*}:/mnt" ubuntu:bionic /mnt/env/autogen_.sh "${PWD##*/}" "$@"
fi
