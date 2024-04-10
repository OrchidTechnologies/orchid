#!/bin/bash
set -e
set -o pipefail
git grep 'NOLINT\(NEXTLINE\|BEGIN\)(' | sed -e 's/.*(//;s/)//' | tr ',' $'\n' | sort | uniq -c
