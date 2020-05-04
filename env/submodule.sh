#!/bin/bash
set -e
# XXX: flutter needs deep for an unknown reason; maybe this can be fixed?
# XXX: the other repositories need uploadpack.allowReachableSHA1InWant :(
# XXX: nettle works if you use -c protocol.version=2, but I don't want to
git submodule update --init --recursive "$@" -- app-shared/flutter min-wireshark/{gnulib,libiconv} p2p/{lwip,nettle} vpn-shared/{libssh,tor}
git submodule update --init --recursive "$@" --depth 1
