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

archs += aarch64
openssl/aarch64 := linux-aarch64
host/aarch64 := aarch64-linux-gnu
meson/aarch64 := aarch64

include $(pwd)/target-gnu.mk

lflags += -Wl,--icf=all
lflags += -pthread
qflags += -fPIC

ifeq ($(filter crossndk,$(debug))$(uname-s),Linux)

define _
ranlib/$(1) := ranlib
ar/$(1) := ar
strip/$(1) := strip
endef
$(each)

cc := clang$(suffix)
cxx := clang++$(suffix)

cxx += -stdlib=libc++

else

more := 
more += --sysroot $(CURDIR)/$(output)/sysroot
more += --gcc-toolchain=$(CURDIR)/$(output)/sysroot/usr
include $(pwd)/target-ndk.mk

xflags += -nostdinc++
xflags += -isystem $(CURDIR)/$(pwd)/libcxx/include

lflags += -lrt

source += $(wildcard $(pwd)/libcxx/src/*.cpp)
c_libcxx += -D_LIBCPP_BUILDING_LIBRARY
c_libcxx += -D__GLIBCXX__

define _
more/$(1) := 
more/$(1) += -B$(llvm)/$(1)-linux-android/bin
more/$(1) += -target $(1)-pc-linux-gnu
ranlib/$(1) := $(llvm)/bin/$(1)-linux-android-ranlib
ar/$(1) := $(llvm)/bin/$(1)-linux-android-ar
strip/$(1) := $(llvm)/bin/$(1)-linux-android-strip
endef
$(each)

$(output)/sysroot: env/sysroot.sh env/sysroot_.sh
	env/sysroot.sh

.PHONY: sysroot
sysroot: $(output)/sysroot

sysroot += $(output)/sysroot

endif

default := x86_64
