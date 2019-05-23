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
cflags += -Wno-tautological-constant-out-of-range-compare

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

cflags += -I$(pwd)/url/include

cflags += $(patsubst %,-I%,$(wildcard $(pwd)/boost/libs/*/include))
cflags += $(patsubst %,-I%,$(wildcard $(pwd)/boost/libs/numeric/*/include))
cflags += -I$(pwd)/boost/libs/asio/include/boost

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
source += $(wildcard $(pwd)/boost/libs/random/src/*.cpp)
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

$(output)/gen_context: pwd := $(pwd)
$(output)/gen_context: $(pwd)/secp256k1/src/gen_context.c
	gcc -o $@ $< -I$(pwd)/secp256k1

$(pwd)/secp256k1/src/ecmult_static_context.h: pwd := $(pwd)
$(pwd)/secp256k1/src/ecmult_static_context.h: $(output)/gen_context
	cd $(pwd)/secp256k1 && $(PWD)/$(output)/gen_context

$(output)/$(pwd)/secp256k1/src/secp256k1.o: $(pwd)/secp256k1/src/ecmult_static_context.h

cflags += -DENABLE_MODULE_RECOVERY
cflags += -DENABLE_MODULE_ECDH
cflags += -DUSE_ECMULT_STATIC_PRECOMPUTATION
cflags += -DUSE_FIELD_INV_BUILTIN
cflags += -DUSE_NUM_NONE
cflags += -DUSE_SCALAR_INV_BUILTIN
cflags += -DUSE_FIELD_5X52
cflags += -DUSE_SCALAR_4X64
cflags += -DHAVE___INT128


include $(pwd)/rtc/target.mk
