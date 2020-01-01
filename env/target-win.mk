# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2019  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


dll := dll
lib := lib
exe := .exe

meson := windows

archs += i686
openssl/i686 := mingw
host/i686 := i686-w64-mingw32
meson/i686 := x86
bits/i686 := 32

archs += x86_64
openssl/x86_64 := mingw64
host/x86_64 := x86_64-w64-mingw32
meson/x86_64 := x86_64
bits/x86_64 := 64

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
include $(pwd)/target-ndk.mk
cxx += -stdlib=libc++

define _
ranlib/$(1) := $(1)-w64-mingw32-ranlib
ar/$(1) := $(1)-w64-mingw32-ar
strip/$(1) := $(1)-w64-mingw32-ar
windres/$(1) := $(1)-w64-mingw32-windres
endef
$(each)

lflags += -static
lflags += -lc++
lflags += -lc++abi
lflags += -pthread

wflags += -fuse-ld=ld
lflags += -Wl,--no-insert-timestamp

#cflags += -DNOMINMAX
cflags += -DWIN32_LEAN_AND_MEAN=

#cflags += -fms-compatibility
#cflags += -D__GNUC__

mflags += has_function_stpcpy=false

# pragma comment(lib, "...lib")
# pragma warning(disable : ...)
cflags += -Wno-pragma-pack
cflags += -Wno-unknown-pragmas

cflags += -Wno-unused-const-variable

cflags += -I$(pwd)/win32
cflags += -Wno-nonportable-include-path

msys2 := 
msys2 += crt-git-7.0.0.5397.291c4f8d-1
msys2 += dlfcn-1.1.2-1
msys2 += gcc-9.2.0-2
msys2 += headers-git-7.0.0.5397.291c4f8d-1
msys2 += libc++-8.0.0-8
msys2 += libc++abi-8.0.0-8
msys2 += winpthreads-git-7.0.0.5325.11a5459d-1

define _
$(output)/$(1)/%.msys2:
	@mkdir -p $$(dir $$@)
	curl http://repo.msys2.org/mingw/$(1)/mingw-w64-$(1)-$$*-any.pkg.tar.xz | tar -C $(output)/$(1) -Jxvf-
	@touch $$@

sysroot += $(patsubst %,$(output)/$(1)/%.msys2,$(msys2))
endef
$(each)

default := x86_64
