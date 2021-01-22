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


args := 

include env/target.mk

.PHONY: all
all: $(output)/$(machine)/orchid$(exe)

.PHONY: test
test: $(output)/$(machine)/orchid$(exe)
	$< $(args)

.PHONY: debug
debug: $(output)/$(machine)/orchid$(exe)
	lldb -o 'run $(args)' $<

$(call include,p2p/target.mk)
$(call include,zlb/target.mk)

source += $(wildcard source/*.cpp)

cflags += -I$(pwd)/p2p/boost/libs/iostreams/include

source += $(pwd)/p2p/boost/libs/iostreams/src/gzip.cpp
source += $(pwd)/p2p/boost/libs/iostreams/src/zlib.cpp

include env/output.mk

$(output)/%/orchid$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@echo [LD] $@
	@set -o pipefail; $(cxx) $(more/$*) $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(filter %.lib,$^) $(lflags) 2>&1 | nl
	@ls -la $@
