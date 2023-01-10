#!/bin/bash
set -e
which brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install autoconf autoconf-archive automake capnp fakeroot libtool meson rpm rustup-init zstd
rustup-init -y --no-modify-path --no-update-default-toolchain
env/setup-all.sh
