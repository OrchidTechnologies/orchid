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

.PHONY: all
all: $(output)/orchid$(exe)

.PHONY: test
test: $(output)/orchid$(exe)
	$(output)/orchid$(exe)


source += $(wildcard source/*.cpp)
cflags += -Isource

source += $(wildcard p2p/boost/libs/program_options/src/*.cpp)

include p2p/target.mk

cflags += -Iextra


include env/output.mk
include p2p/depend.mk


$(output)/orchid$(exe): $(object) $(linked)
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cycp) $(wflags) -o $@ $^ $(lflags)
