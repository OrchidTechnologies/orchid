# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

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
cflags += -Wno-misleading-indentation
cflags += -Wno-missing-selector-name
cflags += -Wno-overloaded-shift-op-parentheses
cflags += -Wno-potentially-evaluated-expression
cflags += -Wno-tautological-constant-out-of-range-compare
cflags += -Wno-tautological-overlap-compare


cflags += -fcoroutines-ts
cflags += -Wno-deprecated-experimental-coroutine

cflags += -I$(pwd)/extra


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

$(call depend,$(pwd)/source/version.cpp.o,@/extra/revision.hpp)


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
else
source += $(pwd)/lwip/contrib/ports/unix/port/sys_arch.c
cflags += -I$(pwd)/lwip/contrib/ports/unix/port/include
endif

cflags += -I$(pwd)/lwip/src/include

cflags += -DLWIP_ERRNO_STDINCLUDE


# Android sockaddr_storage is more indirect
ifeq ($(target),and)
cflags/$(pwd)/lwip/ += -Wno-missing-braces
cflags/$(pwd)/source/lwip.cpp += -Wno-missing-braces
endif

cflags += -I$(pwd)/BeastHttp/BeastHttp/include
#source += $(pwd)/boost/libs/regex/src/regex_traits_defaults.cpp
source += $(wildcard $(pwd)/boost/libs/filesystem/src/*.cpp)
source += $(wildcard $(pwd)/boost/libs/json/src/*.cpp)
source += $(wildcard $(pwd)/boost/libs/program_options/src/*.cpp)
source += $(wildcard $(pwd)/boost/libs/random/src/*.cpp)
source += $(wildcard $(pwd)/boost/libs/regex/src/*.cpp)

# XXX: https://github.com/boostorg/beast/issues/2282
checks/$(pwd)/source/base64.cpp += -clang-analyzer-core.UndefinedBinaryOperatorResult

cflags/$(pwd)/boost/libs/filesystem/src/unique_path.cpp += -Wno-unused-function

ifeq ($(target),win)
cflags/$(pwd)/boost/libs/filesystem/src/operations.cpp += -Wno-unused-const-variable
# XXX https://github.com/boostorg/filesystem/issues/206
cflags/$(pwd)/boost/libs/filesystem/src/path.cpp += -Wno-inconsistent-missing-override
cflags/$(pwd)/boost/libs/filesystem/src/windows_file_codecvt.cpp += -Wno-inconsistent-missing-override
endif


#cflags += -DCTRE_ENABLE_LITERALS
cflags += -I$(pwd)/ctre/single-header


source += $(wildcard $(pwd)/jsoncpp/src/lib_json/*.cpp)
cflags += -I$(pwd)/jsoncpp/include

# XXX: I'm using a deprecated jsoncpp API surface
cflags += -Wno-deprecated-declarations


source += $(pwd)/SHA3IUF/sha3.c
cflags += -I$(pwd)/SHA3IUF


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
cflags += -DPOSIX=5
endif


pwd/secp256k1 := $(pwd)/secp256k1
source += $(pwd/secp256k1)/src/secp256k1.c
source += $(pwd/secp256k1)/src/precomputed_ecmult.c
source += $(pwd/secp256k1)/src/precomputed_ecmult_gen.c
cflags += -I$(pwd/secp256k1)/include

cflags/$(pwd/secp256k1)/ += -I$(pwd/secp256k1)
cflags/$(pwd/secp256k1)/ += -I$(pwd/secp256k1)/src
cflags/$(pwd/secp256k1)/ += -Wno-unused-function

cflags += -DENABLE_MODULE_RECOVERY
cflags += -DENABLE_MODULE_ECDH
cflags += -DECMULT_WINDOW_SIZE=15
cflags += -DECMULT_GEN_PREC_BITS=4


cflags += -I$(pwd)/intx/include

source += $(filter-out %/fmt.cc,$(wildcard $(pwd)/fmt/src/*.cc))
cflags += -I$(pwd)/fmt/include

source += $(pwd)/eEVM/3rdparty/keccak/KeccakHash.c
source += $(pwd)/eEVM/3rdparty/keccak/KeccakSpongeWidth1600.c
source += $(pwd)/eEVM/3rdparty/keccak/KeccakP-1600-opt64.c

cflags += -I$(pwd)/eEVM/3rdparty
cflags += -I$(pwd)/eEVM/include


linked += $(pwd)/challenge-bypass-ristretto-ffi/librust.a
cflags += -I$(pwd)/challenge-bypass-ristretto-ffi/src
source += $(pwd)/challenge-bypass-ristretto-ffi/src/wrapper.cpp


linked += $(pwd)/boringtun/librust.a
cflags += -I$(pwd)/boringtun/src


source += $(pwd)/SPCDNS/src/codec.c
source += $(pwd)/SPCDNS/src/mappings.c
source += $(pwd)/SPCDNS/src/output.c
cflags += -I$(pwd)/SPCDNS/src


cflags += -I$(pwd)/cpp-jwt/include


source += $(pwd)/bech32/ref/c++/bech32.cpp
cflags += -I$(pwd)/bech32/ref/c++

# for (const char& c : hrp) assert(c < 'A' || c > 'Z');
cflags/$(pwd)/bech32/ += -Wno-unused-variable


source += $(pwd)/pugixml/src/pugixml.cpp
cflags += -I$(pwd)/pugixml/src
cflags += -DPUGIXML_HAS_LONG_LONG


source += $(pwd)/snappy/snappy.cc
source += $(pwd)/snappy/snappy-sinksource.cc
cflags += -I$(pwd)/snappy


include $(pwd)/asio.mk
include $(pwd)/protobuf.mk

$(eval $(call protobuf,,$(pwd)/trezor-common/protob))
source += $(output)/pb/messages.pb.cc
header += $(output)/pb/messages.pb.h
source += $(output)/pb/messages-common.pb.cc
header += $(output)/pb/messages-common.pb.h
source += $(output)/pb/messages-ethereum.pb.cc
header += $(output)/pb/messages-ethereum.pb.h
source += $(output)/pb/messages-management.pb.cc
header += $(output)/pb/messages-management.pb.h

$(call include,rtc/target.mk)
$(call include,krypton/target.mk)
$(call include,c-ares.mk)
$(call include,openvpn3.mk)
$(call include,sqlite.mk)
