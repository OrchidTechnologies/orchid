#!/bin/bash
set -e
shopt -s extglob

case "$1" in
    (1*([0-9])) prefix="$1:";;

    (+([0-9]).+([0-9]).+([0-9]))
        binary=$(echo "$1" | sed -e 's/\./*2^42+/;s/\./*2^21+/;s/^/obase=2;(/;s/$/)/' | bc)
        prefix=$(echo "ibase=2;${binary:0:31}" | bc):$(echo "obase=16;ibase=2;${binary:31:16}" | bc | tr "[:upper:]" "[:lower:]")
    ;;

    (*)
        echo "unknown format" 1>&2
        exit 1
    ;;
esac

git log --pretty=format:%ct:%H | sed -e "/^${prefix}/{s/^[^:]*://;p;};d"
