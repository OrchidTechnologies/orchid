#!/bin/bash
set -e
which brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# XXX: duplicate linux setup as much as possible
brew install \
    gnu-sed \
    fakeroot \
    rpm2cpio zstd \
    binutils \
    mingw-w64 \
    python-packaging \
    groff \
    autoconf{,-archive} automake libtool \
    make ninja pkg-config \
    cmake meson \
    rustup-init \

rustup-init -y --no-modify-path --no-update-default-toolchain
env/setup-all.sh
