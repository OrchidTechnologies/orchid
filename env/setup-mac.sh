#!/bin/bash
set -e
brew install meson autoconf automake libtool rpm
pip install pyyaml
env/setup-all.sh
