#!/bin/bash
set -e
src=$1
shift
cd "${src}"
if [[ -e ./autogen.sh ]]; then
    ./autogen.sh
else
    if grep AC_CONFIG_HEADERS configure.ac &>/dev/null; then
        autoheader
    fi
    autoconf
fi
