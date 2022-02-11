#!/bin/sh
set -euo pipefail

for f in *.arb
do
    echo $f
    jq < $f > $f.$$
    mv $f.$$ $f
done
