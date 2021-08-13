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


args := --price 0 --currency USD

args += --chain 1,ETH,https://cloudflare-eth.com/
args += --chain 30,BTC,https://public-node.rsk.co/
args += --chain 56,BNB,https://bsc-dataseed.binance.org/
args += --chain 100,DAI,https://rpc.xdaichain.com/
args += --chain 137,MATIC,https://rpc-mainnet.maticvigil.com/
args += --chain 43114,AVAX,https://api.avax.network/ext/bc/C/rpc
#args += --chain 1313161554,NEAR,https://rpc.mainnet.near.org/

include env/target.mk

binary := $(output)/$(machine)/orchidd$(exe)

.PHONY: all
all: $(binary)

.PHONY: test
test: $(binary)
	$< $(args)

.PHONY: debug
debug: $(binary)
	lldb -o 'b malloc_error_break' -o 'run $(args)' $<

.PHONY: record
record: $(output)/$(machine)/orchidd$(exe)
	perf record --call-graph dwarf $< $(args)

.PHONY: report
report:
	perf report --sort=cpu

.PHONY: install
install: $(binary)
	cp -a $< $(usr)/sbin/

source += $(wildcard $(pwd)/source/*.cpp)
cflags += -I$(pwd)/extra
cflags += -I$(pwd)/source

$(call include,p2p/target.mk)
$(call include,cv8/target.mk)

cflags += -Iall/vpn-shared/source
ifeq ($(target),lnx)
cflags += -Iall/vpn-linux/source
source += all/vpn-linux/source/tunnel.cpp
endif


# XXX: this should be done as part of env/output.mk for all autoconf builds
p_libuv := -D__FILE__='\"libuv/*\"' -Wno-builtin-macro-redefined

libuv := 
libuv += libuv.a
libuv := $(patsubst %,$(pwd)/libuv/.libs/%,$(libuv))

$(subst @,%,$(patsubst %,$(output)/@/%,$(libuv))) \
: $(output)/%/$(pwd)/libuv/Makefile $(sysroot)
	$(MAKE) -C $(dir $<)

linked += $(libuv)

cflags += -I$(pwd)/libuv/include


include mediasoup.mk


cflags += -I$(pwd)/di/include
cflags += -I$(pwd)/GSL/include
cflags += -I$(pwd)/hat-trie/include
cflags += -I$(pwd)/sqlite_modern_cpp/hdr


source += $(wildcard $(pwd)/yaml-cpp/src/*.cpp)
cflags += -I$(pwd)/yaml-cpp/include


source += $(pwd)/soralog/src/group.cpp
source += $(pwd)/soralog/src/logger.cpp
source += $(pwd)/soralog/src/logging_system.cpp
source += $(pwd)/soralog/src/impl/fallback_configurator.cpp
source += $(pwd)/soralog/src/impl/sink_to_console.cpp
source += $(pwd)/soralog/src/impl/sink_to_nowhere.cpp
cflags += -I$(pwd)/soralog/include
cflags/$(pwd)/soralog/ += -Wno-reorder -Wno-unused-function -Wno-unused-variable
cflags/$(pwd)/soralog/ += -Wno-pessimizing-move


source += $(filter-out %/configurator.cpp,$(shell find $(pwd)/cpp-libp2p/src -name '*.cpp'))
cflags += -I$(pwd)/cpp-libp2p/include
cflags/$(pwd)/cpp-libp2p/ += -Wno-reorder -Wno-unused
# XXX: https://github.com/libp2p/cpp-libp2p/issues/162
cflags/$(pwd)/cpp-libp2p/src/protocol/gossip/impl/gossip_core.cpp += -Wno-mismatched-tags

$(eval $(call protobuf,/generated,$(pwd)/cpp-libp2p/src))
source += $(output)/pb/generated/crypto/protobuf/keys.pb.cc
header += $(output)/pb/generated/crypto/protobuf/keys.pb.h
source += $(output)/pb/generated/protocol/gossip/protobuf/rpc.pb.cc
header += $(output)/pb/generated/protocol/gossip/protobuf/rpc.pb.h
source += $(output)/pb/generated/protocol/identify/protobuf/identify.pb.cc
header += $(output)/pb/generated/protocol/identify/protobuf/identify.pb.h
source += $(output)/pb/generated/protocol/kademlia/protobuf/kademlia.pb.cc
header += $(output)/pb/generated/protocol/kademlia/protobuf/kademlia.pb.h
source += $(output)/pb/generated/security/noise/protobuf/noise.pb.cc
header += $(output)/pb/generated/security/noise/protobuf/noise.pb.h
source += $(output)/pb/generated/security/plaintext/protobuf/plaintext.pb.cc
header += $(output)/pb/generated/security/plaintext/protobuf/plaintext.pb.h
source += $(output)/pb/generated/security/secio/protobuf/secio.pb.cc
header += $(output)/pb/generated/security/secio/protobuf/secio.pb.h


include env/output.mk

$(output)/%/orchidd$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx) $(more/$*) $(wflags) -o $@ $^ $(lflags)
	@openssl sha256 -r $@
	@ls -la $@
