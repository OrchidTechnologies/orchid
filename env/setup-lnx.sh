#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
sudo -EH apt-get -y install bc bison cpio flex gettext gperf groff ninja-build python python3-pip python3-setuptools rpm tcl
sudo -EH pip3 install meson

env/setup-all.sh
