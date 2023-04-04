# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pre := lib
dll := so
lib := a
exe := 

ifeq ($(libc),)
libc := gnu
endif

meson := linux

archs += i386
openssl/i386 := linux-x86
host/i386 := i386-linux-$(libc)
triple/i386 := i686-unknown-linux-$(libc)
meson/i386 := x86
bits/i386 := 32
centos/i386 := i686

archs += x86_64
openssl/x86_64 := linux-x86_64
host/x86_64 := x86_64-linux-$(libc)
triple/x86_64 := x86_64-unknown-linux-$(libc)
meson/x86_64 := x86_64
bits/x86_64 := 64
centos/x86_64 := x86_64

archs += arm64
openssl/arm64 := linux-aarch64
host/arm64 := aarch64-linux-$(libc)
triple/arm64 := aarch64-unknown-linux-$(libc)
meson/arm64 := aarch64
bits/arm64 := 64

archs += armhf
openssl/armhf := linux-armv4
host/armhf := arm-linux-$(libc)eabihf
triple/armhf := arm-unknown-linux-$(libc)eabihf
meson/armhf := arm
bits/armhf := 32

archs += mips
openssl/mips := linux-mips32
host/mips := mips-linux-$(libc)
triple/mips := mips-unknown-linux-$(libc)
meson/mips := mips
bits/mips := 32

ifeq ($(machine),)
machine := $(uname-m)
endif

more := --gcc-toolchain=$(CURDIR)/$(output)/sysroot/usr

define _
more/$(1) := -target $(host/$(1))
ifneq ($(centos/$(1)),)
more/$(1) += --sysroot $(CURDIR)/$(output)/sysroot
else
more/$(1) += --sysroot $(CURDIR)/$(output)/sysroot/usr/$(host/$(1))
endif
endef
$(each)

ifeq ($(distro),)
ifneq ($(centos/$(machine)),)
distro := centos6 $(machine) $(centos/$(machine))
else
distro := ubuntu bionic 7
endif
endif

sysroot += $(output)/sysroot

# XXX: consider naming sysroot folder after distro
$(output)/sysroot: env/sys-$(word 1,$(distro)).sh env/setup-sys.sh
	+$< $@ $(wordlist 2,$(words $(distro)),$(distro)) || { rm -rf $@; false; }

.PHONY: sysroot
sysroot: $(output)/sysroot

include $(pwd)/target-elf.mk
lflags += -Wl,--hash-style=gnu

ifeq ($(filter crossndk,$(debug))$(uname-s),Linux)
include $(pwd)/kit-default.mk
define _
strip/$(1) := strip
windres/$(1) := false
endef
$(each)
else
include $(pwd)/kit-android.mk
define _
strip/$(1) := $(llvm)/bin/$(1)-linux-android-strip
windres/$(1) := false
endef
$(each)
define _
more/$(1) += -B$(llvm)/$(subst -$(libc),-android,$(host/$(1)))/bin
endef
$(each)
endif

include $(pwd)/target-cxx.mk

# XXX: v8 requires armv6k for the "yield" instruction
more/armhf += -march=armv6k -D__ARM_MAX_ARCH__=8

lflags += -ldl
lflags += -lrt
lflags += -pthread
