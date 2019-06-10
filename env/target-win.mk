# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


dll := dll
lib := lib
exe := .exe

#arch := i686
#ossl := mingw

arch := x86_64
ossl := mingw64

host := $(arch)-w64-mingw32

include $(pwd)/target-ndk.mk

more := 
more += -target $(arch)-pc-windows-gnu 
more += --sysroot $(CURDIR)/$(output)/mingw64
more += -D_WIN32_WINNT=0x0600

cycc := $(llvm)/bin/clang $(more)
cycp := $(llvm)/bin/clang++ $(more) -stdlib=libc++

ranlib := $(arch)-w64-mingw32-ranlib
ar := $(arch)-w64-mingw32-ar

lflags += -static
lflags += -lc++
lflags += -lc++abi
lflags += -pthread

temp := $(shell which $(arch)-w64-mingw32-ld)
ifeq ($(temp),)
$(error $(arch)-w64-mingw32-ld must be on your path)
endif
wflags += -fuse-ld=ld -B$(dir $(temp))$(arch)-w64-mingw32-

cflags += -DNOMINMAX
cflags += -DWIN32_LEAN_AND_MEAN=

#cflags += -fms-compatibility
#cflags += -D__GNUC__

# pragma comment(lib, "...lib")
# pragma warning(disable : ...)
cflags += -Wno-unknown-pragmas

msys2 := 
msys2 += crt-git-7.0.0.5397.291c4f8d-1
msys2 += dlfcn-1.1.2-1
msys2 += gcc-8.3.0-2
msys2 += headers-git-7.0.0.5397.291c4f8d-1
msys2 += libc++-8.0.0-2
msys2 += libc++abi-8.0.0-2
msys2 += winpthreads-git-7.0.0.5325.11a5459d-1

$(output)/%.msys2:
	@mkdir -p $(dir $@)
	@curl http://repo.msys2.org/mingw/x86_64/mingw-w64-x86_64-$*-any.pkg.tar.xz | tar -C $(output) -Jxvf-
	@touch $@

linker += $(patsubst %,$(output)/%.msys2,$(msys2))
