#!/bin/sh
#
# Read all of the arb files and check for missing keys as compared to 'en'.
#
en=intl_en.arb
keys=/tmp/en.$$
check=/tmp/check.$$

function keys() {
    jq 'keys[]' | grep -v '@' | sort -u 
}

cat intl_en.arb | keys > $keys

GLOBIGNORE="$en"
for f in *.arb
do
    cat $f | keys > $check
    d=$(diff $keys $check)
    if [ ! -z "$d" ]
    then 
        echo "\n$f keys differ:"
        echo "$d"
    fi
done

rm $keys $check
