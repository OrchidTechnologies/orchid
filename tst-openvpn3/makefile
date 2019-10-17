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


include env/target.mk

version := 0.9

args := ../PureVPN.ovpn -x -u "$(username)" -p "$(password)"

.PHONY: all
all: $(output)/$(default)/orchid$(exe)

.PHONY: test
test: $(output)/$(default)/orchid$(exe)
	sudo $< $(args)

.PHONY: debug
debug: $(output)/$(default)/orchid$(exe)
	sudo lldb -o 'run $(args)' $<

source += $(wildcard vpn/lz4/lib/*.c)
cflags += -Ivpn/lz4/lib

cflags += -DUSE_ASIO
cflags += -DUSE_ASIO_THREADLOCAL
cflags += -DASIO_NO_DEPRECATED
cflags += -DHAVE_LZ4
cflags += -DUSE_OPENSSL

cflags += -Ivpn/openvpn3
cflags += -Ivpn/openvpn3/client

c_openvpn3 += -Wno-address-of-temporary
c_openvpn3 += -Wno-delete-non-virtual-dtor
c_openvpn3 += -Wno-inconsistent-missing-override

ifeq ($(target),ios)
c_openvpn3 += -ObjC++
endif

cflags += -Ivpn/p2p/source

$(call include,vpn/p2p/asio.mk)
$(call include,vpn/p2p/rtc/openssl.mk)

source += vpn/openvpn3/test/ovpncli/cli.cpp
source += vpn/p2p/source/log.cpp

lflags += -framework CoreServices
lflags += -framework Foundation
lflags += -framework IOKit
lflags += -framework SystemConfiguration

include env/output.mk

$(output)/%/orchid: $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@echo [LD] $@
	@set -o pipefail; $(cxx/$*) $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(lflags) 2>&1 | nl
	@ls -la $(output)/orchid
