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


target := mac
include env/target.mk

version := 0.9

args := 

.PHONY: all
all: $(output)/orchid

.PHONY: test
test: $(output)/orchid$(exe)
	sudo $(output)/orchid$(exe) $(args)

.PHONY: debug
debug: $(output)/orchid$(exe)
	sudo lldb -o 'run $(args)' $(output)/orchid$(exe)

include vpn/target.mk

ifeq ($(target),mac)
cflags += -Iall/vpn-apple
source += all/vpn-apple/protect.cpp
endif
ifeq ($(target),win)
cflags += -Iall/vpn-windows/tap-windows6/src
endif

source += $(wildcard source/*.cpp)

include env/output.mk

$(output)/orchid: $(object) $(linked) $(output)/GeoLite2-City.mmdb
	@echo [LD] $@
	@set -o pipefail; $(cycp) $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(lflags) 2>&1 | nl
	@ls -la $(output)/orchid
