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

distro := ubuntu bionic 7
include env/target.mk

source := 

binary := $(output)/$(machine)/kernel$(exe)

.PHONY: all
all: $(binary)

.PHONY: debug
debug: $(binary)
	lldb -o 'b malloc_error_break' -o 'run $(args)' $<

.PHONY: test
test: $(binary)
	strace -ff $< 2>&1 | grep -Ev '(] |^)(<|(mmap|mprotect|munmap)\()'

source += $(wildcard $(pwd)/source/*.cpp)
source += $(wildcard $(pwd)/source/*.c)

cflags += -I$(pwd)/source


lflags += -nostdlib
lflags += -static
lflags := $(filter-out -l%,$(lflags))
lflags := $(filter-out -pthread,$(lflags))
xflags += -fno-exceptions
cflags += -fno-plt
lflags += -fno-plt
cflags := $(filter-out -D_FORTIFY_SOURCE=%,$(cflags))

ifeq ($(machine),arm64)
# https://github.com/aws/aws-graviton-getting-started/blob/main/c-c%2B%2B.md
cflags += -march=armv8-a+nofp
cflags += -mno-unaligned-access
#-Wl,-z,max-page-size=0x100
endif

worker/$(output)/$(machine)/worker: force
	$(MAKE) -C worker target=lnx machine=$(machine)

$(output)/embed: env/embed.c
	clang -o $@ $<

$(output)/$(machine)/extra/worker.xxd: worker/$(output)/$(machine)/worker $(output)/embed
	@mkdir -p $(dir $@)
	$(output)/embed worker $< >$@

$(call depend,$(pwd)/source/worker.cpp.o,$(output)/$(machine)/extra/worker.xxd)

include env/output.mk

$(output)/%/kernel$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx) $(more/$*) $(wflags) -o $@ $(bflags) $^ $(lflags) -Wl,--color-diagnostics=always -fcolor-diagnostics 2>&1 | nl
	@openssl sha256 -r $@
	@ls -la $@
