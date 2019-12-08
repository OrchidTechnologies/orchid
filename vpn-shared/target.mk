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


source += $(wildcard $(pwd)/source/*.cpp)
cflags += -I$(pwd)/source

cflags += -I$(pwd)/extra

source += $(wildcard $(pwd)/libmaxminddb/src/*.c)
cflags += -I$(pwd)/libmaxminddb/include
c_libmaxminddb := -DUNICODE

cflags += -DMMDB_UINT128_IS_BYTE_ARRAY

source += $(pwd)/SPCDNS/src/codec.c
source += $(pwd)/SPCDNS/src/mappings.c
source += $(pwd)/SPCDNS/src/output.c
cflags += -I$(pwd)/SPCDNS/src

%/GeoLite2-City.mmdb:
	@mkdir -p $(dir $@)
	curl https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz | tar -C $(dir $@) --strip-components 1 --exclude '*.txt' -zxvf-

$(call include,duktape.mk)
$(call include,sqlite.mk)

#$(call include,tor.mk)
$(call include,libevent.mk)
$(call include,zlib.mk)

$(call include,wsk/target.mk)
$(call include,p2p/target.mk)
