#!/bin/bash
set -e
# XXX: flutter needs deep for an unknown reason; maybe this can be fixed?
# XXX: the other repositories need uploadpack.allowReachableSHA1InWant :(
git submodule update --init --recursive "$@" -- app-shared/flutter min-glib/{gnulib,libiconv} p2p/lwip vpn-shared/{libssh,tor}
git submodule update --init --recursive "$@" --depth 1
