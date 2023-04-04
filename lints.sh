#!/bin/bash
set -e
set -o pipefail
git grep 'NOLINT[A-Z]*(' | sed -e 's/.*(//;s/)//' | tr ',' $'\n' | sort | uniq -c
