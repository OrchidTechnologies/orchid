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

grep -Fxv -f<(dexdump *.dex | LANG=C sed -e '/Class descriptor/!d;s/'\''$//;s/.*: '\''//' | sort -u) <(dexdump -d *.dex | LANG=C tr ';' $'\n' | LANG=C sed -e '/.*\(L[a-zA-Z]*\/[a-zA-Z/$]*\)$/{s//\1;/;p;};d;' | sort -u) | grep -v '^L\(android\|androidx/window/\(extensions\|sidecar\)\|com/google/android/play/core\|dalvik/system\|javax\?\|libcore/io\|org/json\|sun/misc\)/'
