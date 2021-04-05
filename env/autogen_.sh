#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install autoconf gettext git-core libtool
src=$1
shift
cd /mnt
cd "${src}"
exec env/autogen__.sh "$@"
