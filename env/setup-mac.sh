#!/bin/bash
set -e
brew install meson autoconf automake libtool fakeroot jq
brew link --force gettext
pip install pyyaml
exec env/setup-all.sh
