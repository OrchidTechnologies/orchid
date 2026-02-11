#!/bin/bash
set -e
file=$1
shift
"$@"
tar -czf "${file}" -C / --one-file-system --exclude=./tmp .
