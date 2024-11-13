#!/bin/bash
set -e
# XXX: flutter needs deep for an unknown reason; maybe this can be fixed?
# XXX: the other repositories need uploadpack.allowReachableSHA1InWant :(
git submodule update --init --recursive "$@" -- app-shared/flutter env/mingw-w64 min-cairo/libpng min-glib/{gnulib,libiconv} lib-protocol/lwip srv-worker/glibc vpn-shared/{libssh,tor}
git submodule update --init --recursive "$@" --depth 1
