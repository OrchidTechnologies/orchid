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

checks/$(pwd)/source/main.cpp += -cppcoreguidelines-pro-type-vararg

lflags += -nostdlib
lflags := $(filter-out -l%,$(lflags))
lflags := $(filter-out -pthread,$(lflags))
lflags += -static

xflags += -fno-exceptions
xflags += -fno-asynchronous-unwind-tables

qflags += -ffreestanding
cflags := $(filter-out -D_FORTIFY_SOURCE=%,$(cflags))

# XXX: separate slide from base
vaddr := 0xffffffffc0200000
ifeq ($(machine),arm64)
# qemu arm virt
paddr := 0x0000000040200000
else
# qemu x86 microvm / default
paddr := 0x0000000000200000
endif

lflags += -Wl,--no-rosegment
lflags += -Wl,--image-base=$(vaddr)
oflags += --change-section-lma "*"-$$(($(vaddr)-$(paddr)))

ifeq ($(machine),x86_64)
# https://eli.thegreenplace.net/2012/01/03/understanding-the-x64-code-models
qflags += -mcmodel=kernel
lflags += -mcmodel=kernel
else
# XXX: consider using large
qflags += -mcmodel=small
lflags += -mcmodel=small
endif

# XXX: this breaks some x86 headers and has no affect on aarch64 +nofp result
#qflags += -mgeneral-regs-only

ifeq ($(machine),arm64)
# https://github.com/aws/aws-graviton-getting-started/blob/main/c-c%2B%2B.md
qflags += -march=armv8-a+nofp
cflags += -mno-unaligned-access
#-Wl,-z,max-page-size=0x100
endif

ifeq ($(machine),x86_64)
qflags += -mno-red-zone
qflags += -mno-sse
cflags/$(pwd)/source/paging.cpp += -m32
cflags/$(pwd)/source/paging.cpp += -g0
oflags/$(pwd)/source/paging.cpp += -O elf64-x86-64
endif

cflags/$(pwd)/source/paging.cpp += -fomit-frame-pointer

worker/$(output)/$(machine)/worker: force
	$(MAKE) -C worker target=lnx machine=$(machine)

$(output)/%/worker.o: worker/$(output)/%/worker
	cd $(dir $<) && $(objcopy/$*) -O $(format/$*) -I binary $(notdir $<) $(CURDIR)/$@ --set-section-alignment '.data=4096' --set-section-flags '.data=alloc,load,readonly,data'
linked += worker.o

include env/output.mk

$(output)/%/kernel$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx) $(more/$*) $(wflags) -o $@- $(bflags) $^ $(lflags) -Wl,--color-diagnostics=always -fcolor-diagnostics 2>&1 | nl
	@$(objcopy) $(oflags) $@- $@
	@test "$$($(objdump/$*) -x $@ | sed -e '/^.*filesz /!d;s///;/ .w.$$/!d;/^0x0000000000000000 /d' | tee >(cat 1>&2))" = ""
	@openssl sha256 -r $@
	@ls -la $@
