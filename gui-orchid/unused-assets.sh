#!/bin/sh
#
# Find unused assets in the apps
#

cd $(dirname "$0")
gen=lib/orchid/orchid_asset.dart
src="lib ../web-ethereum/dapp2/lib ../web-ethereum/dapp_widget/lib"

list=$(cat $gen | grep -o '^ *final [a-z0-9_]\{3,\}' | sed 's/^ *final //')

for s in $list
do
    got=$(egrep --exclude $(basename $gen) -rS "$s" $src)
    if [ -z "$got" ]; then echo "$s"; fi
done | sort -u

