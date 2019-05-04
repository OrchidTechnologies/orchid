# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


dll := dll
exe := .exe

arch := i686
host := $(arch)-w64-mingw32

include $(pwd)/target-ndk.mk

more := -target $(arch)-pc-windows-gnu --sysroot /usr/local/Cellar/mingw-w64/6.0.0_1/toolchain-i686
more += -DWIN32_LEAN_AND_MEAN=
more += -D_WIN32_WINNT=0x0600

cycc := $(llvm)/clang $(more)
cycp := $(llvm)/clang++ $(more) -stdlib=libc++ -isystem /usr/local/Cellar/llvm/8.0.0/include/c++/v1

wflags += -fuse-ld=lld

cflags += -DNOMINMAX

#cflags += -fms-compatibility
#cflags += -D__GNUC__

# pragma comment(lib, "...lib")
# pragma warning(disable : ...)
cflags += -Wno-unknown-pragmas
