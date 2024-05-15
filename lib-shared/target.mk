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


source += $(wildcard $(pwd)/source/*.cpp)
cflags += -I$(pwd)/source
cflags += -I$(pwd)/extra


$(call depend,$(pwd)/source/version.cpp.o,@/extra/revision.hpp)


cflags += -fcoroutines-ts
cflags += -Wno-deprecated-coroutine
cflags += -Wno-deprecated-experimental-coroutine


cflags += -I$(pwd)/cppcoro/include

source += $(pwd)/cppcoro/lib/async_auto_reset_event.cpp
source += $(pwd)/cppcoro/lib/async_manual_reset_event.cpp
source += $(pwd)/cppcoro/lib/async_mutex.cpp
source += $(pwd)/cppcoro/lib/lightweight_manual_reset_event.cpp

ifeq ($(target),win)
source += $(pwd)/cppcoro/lib/win32.cpp
endif


cflags += -I$(pwd)/expected/include
cflags += -I$(pwd)/url/include
cflags += -I$(pwd)/url/src

# XXX: this might be fixed in a later version
cflags/$(pwd)/url/ += -include iterator

source += $(filter-out \
    %/filesystem.cpp \
,$(wildcard \
    $(pwd)/url/src/unicode/*.cpp \
    $(pwd)/url/src/url/*.cpp \
    $(pwd)/url/src/url/percent_encoding/*.cpp \
))


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


cflags += -I$(pwd)/intx/include

source += $(filter-out %/fmt.cc,$(wildcard $(pwd)/fmt/src/*.cc))
cflags += -I$(pwd)/fmt/include

source += $(pwd)/eEVM/3rdparty/keccak/KeccakHash.c
source += $(pwd)/eEVM/3rdparty/keccak/KeccakSpongeWidth1600.c
source += $(pwd)/eEVM/3rdparty/keccak/KeccakP-1600-opt64.c

cflags += -I$(pwd)/eEVM/3rdparty
cflags += -I$(pwd)/eEVM/include


source += $(pwd)/bech32/ref/c++/bech32.cpp
cflags += -I$(pwd)/bech32/ref/c++

# for (const char& c : hrp) assert(c < 'A' || c > 'Z');
cflags/$(pwd)/bech32/ += -Wno-unused-variable

ifeq ($(crypto),)
crypto := openssl
endif
$(call include,$(crypto)/target.mk)

include $(pwd)/asio.mk
$(call include,abseil.mk)
$(call include,secp256k1.mk)
$(call include,sqlite.mk)
