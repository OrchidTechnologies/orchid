# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pre := 
dll := dll
lib := lib
exe := .exe

meson := windows

archs += i686
openssl/i686 := mingw
host/i686 := i686-w64-mingw32
triple/i686 := i686-pc-windows-gnu
meson/i686 := x86
bits/i686 := 32

archs += x86_64
openssl/x86_64 := mingw64
host/x86_64 := x86_64-w64-mingw32
triple/x86_64 := x86_64-pc-windows-gnu
meson/x86_64 := x86_64
bits/x86_64 := 64

ifeq ($(machine),)
machine := x86_64
endif

include $(pwd)/target-gnu.mk

define _
more/$(1) := -target $(1)-pc-windows-gnu 
more/$(1) += --sysroot $(CURDIR)/$(output)/$(1)/mingw$(bits/$(1))
temp := $(shell which $(1)-w64-mingw32-ld)
ifeq ($$(temp),)
$$(error $(1)-w64-mingw32-ld must be on your path)
endif
more/$(1) += -B$$(dir $$(temp))$(1)-w64-mingw32-
endef
$(each)

more := -D_WIN32_WINNT=0x0601

ifeq ($(filter crossndk,$(debug))$(uname-o),Cygwin)

cc := clang$(suffix) $(more)
cxx := clang++$(suffix) $(more)

ifeq ($(tidy)$(filter notidy,$(debug)),)
debug += notidy
endif

ar := llvm-ar

else
include $(pwd)/target-ndk.mk
ar := $(llvm)/bin/llvm-ar
endif

include $(pwd)/target-cxx.mk

source += $(pwd)/libcxx/src/support/win32/locale_win32.cpp
source += $(pwd)/libcxx/src/support/win32/support.cpp
cflags += -D_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS
lflags += -nostdlib++ -lsupc++

define _
ranlib/$(1) := $(1)-w64-mingw32-ranlib
ar/$(1) := $(ar)
strip/$(1) := $(1)-w64-mingw32-strip
windres/$(1) := $(1)-w64-mingw32-windres
endef
$(each)

lflags += -static
lflags += -pthread
lflags += -lssp

include $(pwd)/target-lld.mk
lflags += -Wl,--no-insert-timestamp
lflags += -Wl,-Xlink=-force:multiple

cflags += -DWIN32_LEAN_AND_MEAN=
cflags += -D_CRT_RAND_S=

cflags += -fms-extensions
#cflags += -fms-compatibility
#cflags += -D__GNUC__

#  warning: 'I64' length modifier is not supported by ISO C
qflags += -Wno-format-non-iso

mflags += has_function_stpcpy=false

# pragma comment(lib, "...lib")
# pragma warning(disable : ...)
cflags += -Wno-pragma-pack
cflags += -Wno-unknown-pragmas

qflags += -I$(CURDIR)/$(pwd)/win32
qflags += -Wno-nonportable-include-path

cflags += -I$(pwd)/mingw

mingw := git-8.0.0.6001.98dad1fe

msys2 := 
msys2 += crt-$(mingw)-1
msys2 += dlfcn-1.2.0-2
msys2 += gcc-10.2.0-6
msys2 += headers-$(mingw)-1
msys2 += winpthreads-$(mingw)-3

define _
temp := $(output)/$(1)/mingw$(bits/$(1))/mingw
$$(temp):
	@mkdir -p $$(dir $$@)
	ln -sf $(1)-w64-mingw32 $$@
sysroot += $$(temp)

$(output)/$(1)/%.msys2:
	@mkdir -p $$(dir $$@)
	curl https://repo.msys2.org/mingw/$(1)/mingw-w64-$(1)-$$*-any.pkg.tar.zst | zstd -d | tar -C $(output)/$(1) -xvf-
	@touch $$@
sysroot += $(patsubst %,$(output)/$(1)/%.msys2,$(msys2))
endef
$(each)
