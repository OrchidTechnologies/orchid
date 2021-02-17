#!/bin/bash
set -e
brew install autoconf automake capnp libtool meson rpm rustup-init zstd
rustup-init -y --no-modify-path --no-update-default-toolchain
env/setup-all.sh
