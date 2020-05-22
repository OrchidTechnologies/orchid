#!/bin/bash
set -e
brew install autoconf automake capnp libtool meson rpm
pip install pyyaml
env/setup-all.sh
