#!/bin/bash
set -e
which brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install \
    fakeroot \
    rpm2cpio zstd \
    binutils \
    mingw-w64 \
    python-packaging \
    groff \
    autoconf autoconf-archive automake \
    libtool meson \
    capnp rustup-init \

rustup-init -y --no-modify-path --no-update-default-toolchain
env/setup-all.sh
