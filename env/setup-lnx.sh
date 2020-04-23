#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
. /etc/os-release

curl "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x${NAME}_${VERSION_ID}/Release.key" | sudo -E apt-key add -
sudo -E add-apt-repository "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/x${NAME}_${VERSION_ID}/ /"

sudo -E apt-get -y install bc bison fakeroot flex gettext gperf groff jq ninja-build python python3-pip python3-setuptools skopeo tcl
sudo -E pip3 install meson

exec env/setup-all.sh
