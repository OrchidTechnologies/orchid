#!/bin/bash
set -e

secret=$1
shift 1
cj="$@"

args=("${secret}")

cj bless "${args[@]}" | cj risc0 execute out/derive
cj bless "${args[@]}" | time cj risc0 prove composite receipt.out out/derive
