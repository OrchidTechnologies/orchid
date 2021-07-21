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
args += --tls ../network.p12

include env/target.mk

version := 0.9

.PHONY: all
all: $(output)/$(machine)/orchid$(exe)

.PHONY: test
test: $(output)/$(machine)/orchid$(exe)
	$< $(args)

.PHONY: debug
debug: $(output)/$(machine)/orchid$(exe)
	lldb -o 'run $(args)' $<

$(call include,cro/target.mk)
$(call include,p2p/target.mk)

source += $(wildcard $(pwd)/source/*.cpp)

$(call depend,$(pwd)/source/main.cpp.o,@/$(pwd)/cro/cairo/src/cairo-features.h)

source += $(filter-out \
    %/db_bench.cc \
    %/leveldbutil.cc \
    %_test.cc \
    %/testutil.cc \
    %/env_$(if $(filter win,$(target)),posix,windows).cc \
,$(wildcard $(patsubst %,leveldb/%/*.cc,db table util)))

cflags += -DLEVELDB_PLATFORM_POSIX
cflags += -DLEVELDB_IS_BIG_ENDIAN=0
cflags += -Ileveldb
cflags += -Ileveldb/include
cflags/./leveldb/util/env_posix.cc += -Wno-unused-result

cflags/$(pwd)/source/ += -Wno-implicit-int-float-conversion

cflags += -DORC_FIBER

include env/output.mk

$(output)/%/orchid$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@echo [LD] $@
	@set -o pipefail; $(cxx) $(more/$*) $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(filter %.lib,$^) $(lflags) 2>&1 | nl
	@ls -la $@
