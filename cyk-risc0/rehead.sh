#!/bin/bash
set -e

stop=$1
shift 1
cj="$@"

block=$($cj block)
args=("$(<<<"${block}" jq -r '.hash')")

for ((i = 0; i != stop; ++i)); do
    hash=$(<<<"${block}" jq -r '.hash')
    number=$(<<<"${block}" jq -r '.number')
    args+=("$(cj lve32le "$($cj get "$(printf '0x68%016x%s' "${number}" "${hash##0x}")")")")
    block=$($cj --height "$((number-1))" block)
done

args+=("$(cj lve32le 0x)")

cj bless "${args[@]}" | cj risc0 execute out/rehead
cj bless "${args[@]}" | time cj risc0 prove composite receipt.out out/rehead
