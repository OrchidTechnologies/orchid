#!/bin/bash
set -e

out=$1
shift 1
[[ $# -eq 0 ]]

cd "${out}"

rm -rf dexdump
mkdir dexdump
cd dexdump

unzip ../Orchid.apk '*.dex'

grep -Fxv -f<(dexdump *.dex | sed -e '/Class descriptor/!d;s/'\''$//;s/.*: '\''//' | sort -u) <(dexdump -d *.dex | tr ';' $'\n' | sed -e '/.*\(Landroidx\/[a-zA-Z/]*\)$/{s//\1;/;p;};d;' | sort -u) | grep -v '^Landroidx/window/\(extensions\|sidecar\)/'
