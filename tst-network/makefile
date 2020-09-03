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


args := 
args += --tls ../network.p12

include env/target.mk

version := 0.9

.PHONY: all
all: $(output)/$(default)/orchid$(exe)

.PHONY: test
test: $(output)/$(default)/orchid$(exe)
	$< $(args)

.PHONY: debug
debug: $(output)/$(default)/orchid$(exe)
	lldb -o 'run $(args)' $<

.PHONY: record
record: $(output)/$(default)/orchid$(exe)
	perf record -g $< $(args)

.PHONY: report
report: $(output)/$(default)/orchid$(exe)
	perf report --sort=cpu

$(call include,vpn/target.mk)

source += $(wildcard source/*.cpp)

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

cflags += -DORC_FIBER

include env/output.mk

$(output)/%/orchid$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@echo [LD] $@
	@set -o pipefail; $(cxx) $(more/$*) $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(filter %.lib,$^) $(lflags) 2>&1 | nl
	@ls -la $@
