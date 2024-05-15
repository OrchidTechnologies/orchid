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
include ../chains.mk

distro := ubuntu bionic 7
include env/target.mk

binary := $(output)/$(machine)/orchidd$(exe)

.PHONY: all
all: $(binary)

.PHONY: test
test: $(binary)
	$< $(args)

.PHONY: debug
debug: $(binary)
	lldb -o 'b malloc_error_break' -o 'run $(args)' $<

.PHONY: record
record: $(output)/$(machine)/orchidd$(exe)
	perf record --call-graph dwarf $< $(args)

.PHONY: report
report:
	perf report --sort=cpu

.PHONY: install
install: $(binary)
	cp -a $< $(usr)/sbin/

source += $(wildcard $(pwd)/source/*.cpp)
cflags += -I$(pwd)/extra
cflags += -I$(pwd)/source

$(call include,lib/target.mk)

cflags += -Iall/vpn-shared/source
ifeq ($(target),lnx)
cflags += -Iall/vpn-linux/source
source += all/vpn-linux/source/tunnel.cpp
endif

kernel/$(output)/$(machine)/kernel: force
	$(MAKE) -C kernel target=lnx machine=$(machine)

$(output)/%/kernel.o: kernel/$(output)/%/kernel
	cd $(dir $<) && $(objcopy/$*) -O $(format/$*) -I binary $(notdir $<) $(CURDIR)/$@ --set-section-alignment '.data=4096' --set-section-flags '.data=alloc,load,readonly,data'
linked += kernel.o

include env/output.mk

$(output)/%/orchidd$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx) $(more/$*) $(wflags) -o $@ $^ $(lflags)
	@openssl sha256 -r $@
	@ls -la $@
