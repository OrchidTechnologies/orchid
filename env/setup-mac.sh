#!/bin/bash
set -e
brew install meson autoconf automake libtool
brew link --force gettext
pip install pyyaml
exec env/setup-all.sh
