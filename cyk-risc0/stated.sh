#!/bin/bash
set -e

contract=$1
slot=$2
shift 2
cj="$@"

block=$($cj block)
proof=$($cj --height "$(<<<"${block}" jq -r '.number')" proof "${contract}" "${slot}")

args=()
args+=("$(cj lve32le "$($cj get "$(<<<"${block}" jq -r '"0x68\("0000000000000000\(.number[2:])"[-16:])\(.hash[2:])"')")")")
args+=("${contract}" "$(cj lve32le $(<<<"${proof}" jq -r '.accountProof[]'))")
args+=("${slot}" "$(cj lve32le $(<<<"${proof}" jq -r '.storageProof[].proof[]'))")

cj bless "${args[@]}" | cj risc0 execute out/stated
cj bless "${args[@]}" | time cj risc0 prove composite receipt.out out/stated
