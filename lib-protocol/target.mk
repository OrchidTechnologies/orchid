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


$(call include,shared/target.mk)

source += $(wildcard $(pwd)/source/*.cpp)
cflags += -I$(pwd)/source
cflags += -I$(pwd)/extra

ifeq ($(target),and)
cflags/$(pwd)/source/lwip.cpp += -Wno-missing-braces
endif

$(call include,boringtun.mk)
$(call include,c-ares.mk)
$(call include,jwt.mk)
$(call include,krypton/target.mk)
$(call include,libutp.mk)
$(call include,lwip.mk)
$(call include,openvpn3.mk)
$(call include,pugixml.mk)
$(call include,ristretto.mk)
$(call include,spcdns.mk)
$(call include,trezor.mk)
$(call include,webrtc/target.mk)
