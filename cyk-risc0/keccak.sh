#!/bin/bash
set -e

mkdir -p out && ./risc0.sh clang++ -std=c++23 -o out/keccak keccak.cpp

cj bless "$(cj lve32le "$(echo wow | cj hex)")" | cj risc0 execute out/keccak
cj bless "$(cj lve32le "$(echo wow | cj hex)")" | cj risc0 prove composite receipt.out out/keccak
