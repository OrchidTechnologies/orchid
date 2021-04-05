#!/bin/bash
set -e

src=$1
shift
cd "${src}"

unset MAKEFLAGS
unset MFLAGS

if [[ -e ./autogen.sh ]]; then
    NOCONFIGURE=1 ./autogen.sh "$@"
else
    autoreconf -i
fi
