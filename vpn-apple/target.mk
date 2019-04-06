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

source += $(wildcard $(pwd)/OpenVPNAdapter/Sources/OpenVPNAdapter/*.m)
source += $(wildcard $(pwd)/OpenVPNAdapter/Sources/OpenVPNAdapter/*.mm)
cflags += -I$(pwd)/OpenVPNAdapter/Sources
cflags += -I$(pwd)/OpenVPNAdapter/Sources/OpenVPNAdapter
c_OpenVPNAdapter += -Wno-objc-missing-super-calls
lflags += -framework NetworkExtension
lflags += -framework SystemConfiguration

cflags += -I$(pwd)
c_OpenVPNAdapter += -include external.hpp
cflags_OpenVPNClient += -DOPENVPN_EXTERN=extern

source += $(pwd)/protect.cpp

source += $(pwd)/external.cpp
cflags_external += -fobjc-arc

include $(pwd)/shared/target.mk
