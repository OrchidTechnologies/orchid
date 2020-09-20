#!/bin/bash
set -e
src=$1
shift
cd "${src}"
if [[ -e ./autogen.sh ]]; then
    NOCONFIGURE=1 ./autogen.sh
else
    autoreconf -i
fi
