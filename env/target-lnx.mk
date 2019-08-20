# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


dll := so
lib := a
exe := 

msys := linux

arch := x86_64
ossl := linux-x86_64

host := $(arch)-linux-gnu

include $(pwd)/target-gnu.mk

ifeq ($(uname),Linux)

ranlib := ranlib
ar := ar
strip := strip

cycc := clang$(suffix)
cycp := clang++$(suffix) -stdlib=libc++

else

include $(pwd)/target-ndk.mk

more := -B $(llvm)/$(arch)-linux-android/bin -target $(arch)-pc-linux-gnu --sysroot $(CURDIR)/$(output)/sysroot

cycc := $(llvm)/bin/clang $(more)
cycp := $(llvm)/bin/clang++ $(more) -stdlib=libc++ -isystem $(output)/sysroot/usr/lib/llvm-8/include/c++/v1

$(output)/sysroot:
	env/sysroot.sh

sysroot += $(output)/sysroot

endif

lflags += -Wl,--icf=all
lflags += -pthread
qflags += -fPIC
