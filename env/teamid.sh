#!/bin/bash
set -e
security cms -D -i "$1" | plutil -extract TeamIdentifier xml1 -o - - | tr -d $' \t\n' | sed -e 's/<[^>]*>//g'
