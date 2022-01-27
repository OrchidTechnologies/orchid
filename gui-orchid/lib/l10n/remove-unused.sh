#!/bin/sh

echo "Update this for shared apps"
exit

cd $(dirname "$0")

echo "finding unused strings..."
filterfile=/tmp/unused.$$
./unused.sh | sed 's/^/\"/; s/$/\":/' > $filterfile

echo "removing..."
for f in *.arb
do
    org="$f.org"
    if [ -f $org ]; then echo "Error: File exists: $org"; exit; fi
    cp $f $org
    grep -v -f $filterfile $org > $f
done

