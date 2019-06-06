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

source += $(wildcard $(pwd)/source/*.cpp)
cflags += -I$(pwd)/source

cflags += -I$(pwd)/extra

source += $(wildcard $(pwd)/lz4/lib/*.c)
cflags += -I$(pwd)/lz4/lib

cflags += -DUSE_ASIO
cflags += -DUSE_ASIO_THREADLOCAL
cflags += -DASIO_NO_DEPRECATED
cflags += -DHAVE_LZ4
cflags += -DUSE_OPENSSL
cflags += -DOPENVPN_FORCE_TUN_NULL
cflags += -DUSE_TUN_BUILDER

source += $(wildcard $(pwd)/openvpn3/client/*.cpp)
cflags += -I$(pwd)/openvpn3
cflags += -I$(pwd)/openvpn3/client

cflags += -DOPENVPN_EXTERNAL_TRANSPORT_FACTORY
cflags += -DOPENVPN_EXTERNAL_TUN_FACTORY

cflags_transport += -Wno-unused-private-field

c_openvpn3 += -Wno-address-of-temporary
c_openvpn3 += -Wno-delete-non-virtual-dtor
c_openvpn3 += -Wno-unused-private-field
c_openvpn3 += -Wno-vexing-parse

source += $(wildcard $(pwd)/libmaxminddb/src/*.c)
cflags += -I$(pwd)/libmaxminddb/include
c_libmaxminddb := -DUNICODE

cflags += -DMMDB_UINT128_IS_BYTE_ARRAY

ifeq ($(target),ios)
c_openvpn3 += -ObjC++
endif

%/GeoLite2-City.mmdb:
	@mkdir -p $(dir $@)
	curl https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz | tar -C $(dir $@) --strip-components 1 --exclude '*.txt' -zxvf-

include $(pwd)/zlib.mk
include $(pwd)/libevent.mk
include $(pwd)/tor.mk

include $(pwd)/p2p/target.mk
