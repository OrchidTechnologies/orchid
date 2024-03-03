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

source += $(wildcard $(pwd)/libmaxminddb/src/*.c)
cflags += -I$(pwd)/libmaxminddb/include
cflags/$(pwd)/libmaxminddb/ += -DUNICODE
cflags/$(pwd)/libmaxminddb/ += -Wno-incompatible-pointer-types-discards-qualifiers
cflags/$(pwd)/libmaxminddb/ += -DPACKAGE_VERSION='""'

cflags += -DMMDB_UINT128_IS_BYTE_ARRAY

$(call include,quickjs.mk)

# XXX: tor broke their build by putting a bare "ar" in combine-libs :/
# I figured out where they hid their new issue tracker and am pending.
ifneq (,)
$(call include,tor.mk)
endif

$(call include,libevent.mk)

$(call include,wsk/target.mk)
$(call include,p2p/target.mk)
