#!/bin/bash
set -e
brew install meson autoconf automake libtool rpm
pip install pyyaml
exec env/setup-all.sh
