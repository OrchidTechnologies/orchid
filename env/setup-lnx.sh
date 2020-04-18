#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
sudo -E apt-get -y install bison flex gettext gperf groff ninja-build python3-pip python3-setuptools tcl
sudo -E pip3 install meson
exec env/setup-all.sh
