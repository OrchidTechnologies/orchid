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

.PHONY: all
all: $(output)/orchid

.PHONY: test
test: $(output)/orchid
	$(output)/orchid


source += $(wildcard source/*.cpp)
cflags += -Isource

source += $(wildcard p2p/boost/libs/program_options/src/*.cpp)

include p2p/target.mk

source += $(filter-out libmicrohttpd/src/microhttpd/test_%.c,$(wildcard libmicrohttpd/src/microhttpd/*.c))
cflags += -Ilibmicrohttpd/src/include
cflags += -Wno-tautological-constant-out-of-range-compare
c_libmicrohttpd += -Wno-unused-variable

cflags += -Iextra


include env/output.mk
include p2p/depend.mk


$(output)/orchid: $(object) $(linked)
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cycp) -o $@ $^ $(lflags)
