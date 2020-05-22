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


cflags += -Wno-bitwise-op-parentheses
cflags += -Wno-dangling-else
cflags += -Wno-empty-body
cflags += -Wno-logical-op-parentheses
cflags += -Wno-missing-selector-name
cflags += -Wno-overloaded-shift-op-parentheses
cflags += -Wno-potentially-evaluated-expression
cflags += -Wno-tautological-constant-out-of-range-compare

cflags += -fcoroutines-ts

cflags += -I$(pwd)/extra
# XXX: cflags += -I$(output)/$(pwd)


cflags += -I$(pwd)/cppcoro/include

source += $(pwd)/cppcoro/lib/async_auto_reset_event.cpp
source += $(pwd)/cppcoro/lib/async_manual_reset_event.cpp
source += $(pwd)/cppcoro/lib/async_mutex.cpp
source += $(pwd)/cppcoro/lib/lightweight_manual_reset_event.cpp

ifeq ($(target),win)
source += $(pwd)/cppcoro/lib/win32.cpp
endif


source += $(wildcard $(pwd)/source/*.cpp)
cflags += -I$(pwd)/source


cflags += -I$(pwd)/expected/include
cflags += -I$(pwd)/url/include
cflags += -I$(pwd)/url/src
source += $(filter-out \
    %/filesystem.cpp \
,$(wildcard \
    $(pwd)/url/src/unicode/*.cpp \
    $(pwd)/url/src/url/*.cpp \
    $(pwd)/url/src/url/percent_encoding/*.cpp \
))


source += $(wildcard $(pwd)/lwip/src/api/*.c)
source += $(wildcard $(pwd)/lwip/src/core/*.c)
source += $(wildcard $(pwd)/lwip/src/core/ipv4/*.c)
source += $(wildcard $(pwd)/lwip/src/core/ipv6/*.c)
source += $(pwd)/lwip/src/netif/ethernet.c

ifeq ($(target),win)
source += $(pwd)/lwip/contrib/ports/win32/sys_arch.c
cflags/$(pwd)/lwip/contrib/ports/win32/sys_arch.c += -UWIN32_LEAN_AND_MEAN
cflags += -I$(pwd)/lwip/contrib/ports/win32/include
cflags/$(pwd)/lwip/ += -DLWIP_TIMEVAL_PRIVATE=0
else
source += $(pwd)/lwip/contrib/ports/unix/port/sys_arch.c
cflags += -I$(pwd)/lwip/contrib/ports/unix/port/include
endif

cflags += -I$(pwd)/lwip/src/include

cflags += -DLWIP_ERRNO_STDINCLUDE


# Android sockaddr_storage is more indirect
cflags/$(pwd)/lwip/ += -Wno-missing-braces
cflags/$(pwd)/source/lwip.cpp += -Wno-missing-braces

cflags/$(pwd)/source/transport.cpp += -Wno-unused-private-field

cflags += -I$(pwd)/BeastHttp/BeastHttp/include
#source += $(pwd)/boost/libs/regex/src/regex_traits_defaults.cpp
source += $(wildcard $(pwd)/boost/libs/filesystem/src/*.cpp)
source += $(wildcard $(pwd)/boost/libs/program_options/src/*.cpp)
source += $(wildcard $(pwd)/boost/libs/random/src/*.cpp)
source += $(wildcard $(pwd)/boost/libs/regex/src/*.cpp)

ifeq ($(target),win)
cflags/$(pwd)/boost/libs/filesystem/src/operations.cpp += -Wno-unused-const-variable
endif


source += $(wildcard $(pwd)/jsoncpp/src/lib_json/*.cpp)
cflags += -I$(pwd)/jsoncpp/include


source += $(wildcard $(pwd)/ethash/lib/keccak/*.c)
cflags += -I$(pwd)/ethash/include


source += $(filter-out \
    %/libutp_inet_ntop.cpp \
,$(wildcard $(pwd)/libutp/*.cpp))

cflags += -I$(pwd)/libutp
cflags/$(pwd)/libutp/ += -Wno-unused-const-variable
cflags/$(pwd)/libutp/ += -Wno-unused-variable

ifeq ($(target),win)
source += $(pwd)/libutp/libutp_inet_ntop.cpp
cflags += -DWIN32
else
cflags += -DPOSIX
endif


pwd/secp256k1 := $(pwd)/secp256k1
source += $(pwd/secp256k1)/src/secp256k1.c
cflags += -I$(pwd/secp256k1)/include

cflags/$(pwd/secp256k1)/ += -I$(pwd/secp256k1)
cflags/$(pwd/secp256k1)/ += -I$(pwd/secp256k1)/src
cflags/$(pwd/secp256k1)/ += -include $(pwd/secp256k1)/../field.h

$(output)/gen_context: $(pwd/secp256k1)/src/gen_context.c
	gcc -o $@ $< -I$(pwd/secp256k1) -DECMULT_GEN_PREC_BITS=4

$(pwd/secp256k1)/src/ecmult_static_context.h: $(output)/gen_context
	cd $(pwd/secp256k1) && $(CURDIR)/$(output)/gen_context

$(call depend,$(pwd/secp256k1)/src/secp256k1.c.o,$(pwd/secp256k1)/src/ecmult_static_context.h)

cflags += -DENABLE_MODULE_RECOVERY
cflags += -DENABLE_MODULE_ECDH
cflags += -DUSE_ECMULT_STATIC_PRECOMPUTATION
cflags += -DUSE_FIELD_INV_BUILTIN
cflags += -DUSE_NUM_NONE
cflags += -DUSE_SCALAR_INV_BUILTIN
cflags += -DECMULT_WINDOW_SIZE=15

# XXX: this is also passed to gen_context above
cflags += -DECMULT_GEN_PREC_BITS=4


cflags += -I$(pwd)/intx/include
source += $(pwd)/intx/lib/intx/div.cpp


cflags += -I$(pwd)/fmt/include

source += $(pwd)/eEVM/src/processor.cpp
source += $(pwd)/eEVM/src/stack.cpp
source += $(pwd)/eEVM/src/transaction.cpp
source += $(pwd)/eEVM/src/util.cpp

source += $(pwd)/eEVM/3rdparty/keccak/KeccakHash.c
source += $(pwd)/eEVM/3rdparty/keccak/KeccakSpongeWidth1600.c
source += $(pwd)/eEVM/3rdparty/keccak/KeccakP-1600-opt64.c

cflags += -I$(pwd)/eEVM/3rdparty
cflags += -I$(pwd)/eEVM/include


linked += $(pwd)/challenge-bypass-ristretto/$(pre)rust.$(lib)
cflags += -I$(pwd)/challenge-bypass-ristretto/src


linked += $(pwd)/boringtun/$(pre)rust.$(lib)
cflags += -I$(pwd)/boringtun/src


source += $(pwd)/SPCDNS/src/codec.c
source += $(pwd)/SPCDNS/src/mappings.c
source += $(pwd)/SPCDNS/src/output.c
cflags += -I$(pwd)/SPCDNS/src


include $(pwd)/asio.mk

# XXX: https://reviews.llvm.org/D48567
include $(pwd)/gmp.mk
include $(pwd)/nettle.mk
include $(pwd)/sequoia.mk

$(call include,rtc/target.mk)
$(call include,openvpn3.mk)
