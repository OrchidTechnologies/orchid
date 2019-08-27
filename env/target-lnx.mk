# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2019  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


dll := so
lib := a
exe := 

meson := linux

archs += x86_64
openssl/x86_64 := linux-x86_64
host/x86_64 := x86_64-linux-gnu
meson/x86_64 := x86_64

include $(pwd)/target-gnu.mk

lflags += -Wl,--icf=all
lflags += -pthread
qflags += -fPIC

ifeq ($(uname),Linux)

define _
ranlib/$(1) := ranlib
ar/$(1) := ar
strip/$(1) := strip
endef
$(each)

cc := clang$(suffix)
cxx := clang++$(suffix) -stdlib=libc++

else

define item
more/$(1) := 
more/$(1) += -B$(llvm)/$(1)-linux-android/bin
more/$(1) += -target $(1)-pc-linux-gnu
endef
$(each)

more := --sysroot $(CURDIR)/$(output)/sysroot
include $(pwd)/target-ndk.mk
cxx += -stdlib=libc++
cxx += -isystem $(output)/sysroot/usr/lib/llvm-8/include/c++/v1

$(output)/sysroot:
	env/sysroot.sh

sysroot += $(output)/sysroot

endif

default := x86_64
