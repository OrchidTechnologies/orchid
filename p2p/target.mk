# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# GNU Affero General Public License, Version 3 {{{ */
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# }}}


pwd := ./$(patsubst %/,%,$(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

cflags += -Wno-bitwise-op-parentheses
cflags += -Wno-dangling-else
cflags += -Wno-logical-op-parentheses
cflags += -Wno-missing-selector-name
cflags += -Wno-potentially-evaluated-expression

cflags += -Wno-reorder # XXX: cppcoro/shared_task.hpp

cflags += -fcoroutines-ts

cflags += -I$(pwd)
cflags += -I$(pwd)/cppcoro/include
cflags += -I$(output)/$(pwd)

source += $(pwd)/cppcoro/lib/async_manual_reset_event.cpp
source += $(pwd)/cppcoro/lib/auto_reset_event.cpp
source += $(pwd)/cppcoro/lib/lightweight_manual_reset_event.cpp
source += $(pwd)/cppcoro/lib/spin_mutex.cpp
source += $(pwd)/cppcoro/lib/spin_wait.cpp
source += $(pwd)/cppcoro/lib/static_thread_pool.cpp

source += $(pwd)/baton.cpp
source += $(pwd)/buffer.cpp
source += $(pwd)/client.cpp
source += $(pwd)/crypto.cpp
source += $(pwd)/http.cpp
source += $(pwd)/jsonrpc.cpp
source += $(pwd)/link.cpp
source += $(pwd)/socket.cpp
source += $(pwd)/task.cpp
source += $(pwd)/webrtc.cpp

#source += $(wildcard $(pwd)/curl/lib/*.c $(pwd)/curl/lib/vauth/*.c $(pwd)/curl/lib/vtls/*.c)
#cflags += -I$(pwd)/curl/include
#cflags += -I$(pwd)/curl/lib
#cflags += -DBUILDING_LIBCURL
#lflags += -lz

ifneq (,)
source += $(pwd)/ethereum.cpp
include $(pwd)/aleth.mk
endif

cflags += $(patsubst %,-I%,$(wildcard $(pwd)/boost/libs/*/include))
cflags += $(patsubst %,-I%,$(wildcard $(pwd)/boost/libs/numeric/*/include))

cflags += -include $(pwd)/byte.hpp

source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_box/*.c)
source += $(pwd)/libsodium/src/libsodium/crypto_box/curve25519xsalsa20poly1305/box_curve25519xsalsa20poly1305.c
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_core/*/ref*/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_generichash/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_generichash/blake2b/ref/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_hash/*.c)
source += $(pwd)/libsodium/src/libsodium/crypto_onetimeauth/poly1305/onetimeauth_poly1305.c
source += $(pwd)/libsodium/src/libsodium/crypto_onetimeauth/poly1305/donna/poly1305_donna.c
source += $(pwd)/libsodium/src/libsodium/crypto_pwhash/argon2/argon2-core.c
source += $(pwd)/libsodium/src/libsodium/crypto_scalarmult/curve25519/scalarmult_curve25519.c
source += $(pwd)/libsodium/src/libsodium/crypto_scalarmult/curve25519/ref10/x25519_ref10.c
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_secretbox/*.c)
source += $(pwd)/libsodium/src/libsodium/crypto_stream/chacha20/stream_chacha20.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/salsa20/stream_salsa20.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/salsa20/ref/salsa20_ref.c
source += $(pwd)/libsodium/src/libsodium/crypto_verify/sodium/verify.c
source += $(wildcard $(pwd)/libsodium/src/libsodium/randombytes/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/randombytes/sysrandom/*.c)
source += $(pwd)/libsodium/src/libsodium/sodium/core.c
source += $(pwd)/libsodium/src/libsodium/sodium/runtime.c
source += $(pwd)/libsodium/src/libsodium/sodium/utils.c

cflags += -I$(pwd)/libsodium/src/libsodium/include
cflags += -I$(pwd)/libsodium/src/libsodium/include/sodium
cflags += -DCONFIGURED
c_libsodium += -Wno-unused-variable

cflags += -I$(pwd)/boost/libs/asio/include/boost
#cflags += -DASIO_STANDALONE
#cflags += -I$(pwd)/asio/asio/include

include $(pwd)/rtc/target.mk
