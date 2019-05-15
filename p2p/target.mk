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
cflags += -Wno-empty-body
cflags += -Wno-logical-op-parentheses
cflags += -Wno-missing-selector-name
cflags += -Wno-potentially-evaluated-expression

cflags += -fcoroutines-ts

cflags += -I$(pwd)/extra
cflags += -I$(output)/$(pwd)

cflags += -I$(pwd)/cppcoro/include

source += $(pwd)/cppcoro/lib/async_auto_reset_event.cpp
source += $(pwd)/cppcoro/lib/async_manual_reset_event.cpp
source += $(pwd)/cppcoro/lib/async_mutex.cpp
source += $(pwd)/cppcoro/lib/auto_reset_event.cpp
source += $(pwd)/cppcoro/lib/lightweight_manual_reset_event.cpp
source += $(pwd)/cppcoro/lib/spin_mutex.cpp
source += $(pwd)/cppcoro/lib/spin_wait.cpp
source += $(pwd)/cppcoro/lib/static_thread_pool.cpp

ifeq ($(target),win)
source += $(pwd)/cppcoro/lib/win32.cpp
endif

source += $(wildcard $(pwd)/source/*.cpp)
cflags += -I$(pwd)/source

#include $(pwd)/aleth.mk

cflags += $(patsubst %,-I%,$(wildcard $(pwd)/boost/libs/*/include))
cflags += $(patsubst %,-I%,$(wildcard $(pwd)/boost/libs/numeric/*/include))

cflags += -include $(pwd)/source/byte.hpp

source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_box/*.c)
source += $(pwd)/libsodium/src/libsodium/crypto_box/curve25519xsalsa20poly1305/box_curve25519xsalsa20poly1305.c
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_core/*/ref*/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_generichash/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_generichash/blake2b/ref/*.c)
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_hash/*.c)
source += $(pwd)/libsodium/src/libsodium/crypto_hash/sha512/cp/hash_sha512_cp.c
source += $(pwd)/libsodium/src/libsodium/crypto_onetimeauth/poly1305/onetimeauth_poly1305.c
source += $(pwd)/libsodium/src/libsodium/crypto_onetimeauth/poly1305/donna/poly1305_donna.c
source += $(pwd)/libsodium/src/libsodium/crypto_pwhash/argon2/argon2-core.c
source += $(pwd)/libsodium/src/libsodium/crypto_pwhash/argon2/argon2-fill-block-ref.c
source += $(pwd)/libsodium/src/libsodium/crypto_pwhash/argon2/blake2b-long.c
source += $(pwd)/libsodium/src/libsodium/crypto_scalarmult/curve25519/scalarmult_curve25519.c
source += $(pwd)/libsodium/src/libsodium/crypto_scalarmult/curve25519/ref10/x25519_ref10.c
source += $(wildcard $(pwd)/libsodium/src/libsodium/crypto_secretbox/*.c)
source += $(pwd)/libsodium/src/libsodium/crypto_secretbox/xsalsa20poly1305/secretbox_xsalsa20poly1305.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/chacha20/ref/chacha20_ref.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/chacha20/stream_chacha20.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/salsa20/stream_salsa20.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/salsa20/ref/salsa20_ref.c
source += $(pwd)/libsodium/src/libsodium/crypto_stream/xsalsa20/stream_xsalsa20.c
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

# crypto_pwhash/argon2/argon2-fill-block-ref.c
c_libsodium += -Wno-unknown-pragmas

cflags += -I$(pwd)/boost/libs/asio/include/boost
#cflags += -DASIO_STANDALONE
#cflags += -I$(pwd)/asio/asio/include

ifneq (,)
source += $(wildcard $(pwd)/lwip/src/api/*.c)
source += $(wildcard $(pwd)/lwip/src/core/*.c)
source += $(wildcard $(pwd)/lwip/src/core/ipv4/*.c)
source += $(wildcard $(pwd)/lwip/src/core/ipv6/*.c)
source += $(wildcard $(pwd)/lwip/src/netif/*.c)

ifeq ($(target),win)
#source += $(pwd)/lwip/contrib/ports/win32/sys_arch.c
source += $(pwd)/lwip/contrib/ports/win32/sio.c
endif
endif

cflags += -I$(pwd)/lwip/src/include
cflags += -I$(pwd)/lwip/contrib/ports/unix/port/include

cflags += -DLWIP_ERRNO_STDINCLUDE

cflags += -I$(pwd)/BeastHttp/BeastHttp/include
#source += $(pwd)/boost/libs/regex/src/regex_traits_defaults.cpp
source += $(wildcard $(pwd)/boost/libs/filesystem/src/*.cpp)
source += $(wildcard $(pwd)/boost/libs/regex/src/*.cpp)

ifeq ($(target),win)
c_operations += -Wno-unused-const-variable
endif


source += $(wildcard $(pwd)/jsoncpp/src/lib_json/*.cpp)
cflags += -I$(pwd)/jsoncpp/include


source += $(wildcard $(pwd)/ethash/lib/ethash/*.c)
cflags += -I$(pwd)/ethash/include


source += $(filter-out \
    %/libutp_inet_ntop.cpp \
,$(wildcard $(pwd)/libutp/*.cpp))

cflags += -I$(pwd)/libutp
c_libutp += -Wno-unused-const-variable

ifeq ($(target),win)
source += $(pwd)/libutp/libutp_inet_ntop.cpp
cflags += -DWIN32
else
cflags += -DPOSIX
endif


source += $(pwd)/secp256k1/src/secp256k1.c
cflags += -I$(pwd)/secp256k1
cflags += -I$(pwd)/secp256k1/include
cflags += -I$(pwd)/secp256k1/src

cflags += -DENABLE_MODULE_RECOVERY
cflags += -DENABLE_MODULE_ECDH
cflags += -DUSE_ECMULT_STATIC_PRECOMPUTATION
cflags += -DUSE_FIELD_INV_BUILTIN
cflags += -DUSE_NUM_NONE
cflags += -DUSE_SCALAR_INV_BUILTIN
cflags += -DUSE_FIELD_5X52
cflags += -DUSE_SCALAR_4X64
cflags += -DHAVE_BUILTIN_EXPECT
cflags += -DHAVE___INT128


include $(pwd)/rtc/target.mk
