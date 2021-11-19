#!/bin/bash
set -e
# XXX: flutter needs deep for an unknown reason; maybe this can be fixed?
# XXX: googletest broke recently and doesn't even support HEAD and I sigh
# XXX: the other repositories need uploadpack.allowReachableSHA1InWant :(
git submodule update --init --recursive "$@" -- app-shared/flutter min-cairo/libpng min-glib/{gnulib,libiconv} min-zlib/googletest p2p/lwip vpn-shared/{libssh,tor}
git submodule update --init --recursive "$@" --depth 1
