#!/bin/bash
set -e
brew install meson autoconf automake libtool rpm
brew link --force gettext
pip install pyyaml
exec env/setup-all.sh
