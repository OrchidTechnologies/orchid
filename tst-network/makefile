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
all: $(output)/$(default)/orchid$(exe)

.PHONY: test
test: $(output)/$(default)/orchid$(exe)
	$< $(args)

.PHONY: debug
debug: $(output)/$(default)/orchid$(exe)
	lldb -o 'run $(args)' $<

$(call include,vpn/target.mk)

source += $(wildcard source/*.cpp)

include env/output.mk

$(output)/%/orchid$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@echo [LD] $@
	@set -o pipefail; $(cxx/$*) $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(lflags) 2>&1 | nl
	@ls -la $@
