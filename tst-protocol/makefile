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


args := localhost 8443
include ../chains.mk

# XXX: there is a note about this in cli-shared's makefile
distro := ubuntu bionic 7
include env/target.mk

version := 0.9

.PHONY: all
all: $(output)/$(machine)/orchidget$(exe)

.PHONY: test
test: $(output)/$(machine)/orchidget$(exe)
	$< $(args)

$(call include,vpn/target.mk)

source += $(wildcard $(pwd)/source/*.cpp)

# XXX: this is some kind of weird boost thing
cflags/$(pwd)/source/main.cpp += -Wno-implicit-const-int-float-conversion

include env/output.mk

$(output)/%/orchidget$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@echo [LD] $@
	@set -o pipefail; $(cxx) $(more/$*) $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(filter %.lib,$^) $(lflags) 2>&1 | nl
	@ls -la $@
