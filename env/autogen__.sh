#!/bin/bash
set -e
src=$1
shift
cd "${src}"
if [[ -e ./autogen.sh ]]; then
    ./autogen.sh
else
    autoreconf -i
fi
