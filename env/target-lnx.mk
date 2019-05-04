# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


dll := so
exe := 

arch := x86_64
host := $(arch)-linux-gnu

ifeq ($(uname),Linux)

include $(pwd)/target-gnu.mk

ranlib := ranlib

cycc := clang-8
cycp := clang++-8 -stdlib=libc++

else

include $(pwd)/target-ndk.mk

more := -B $(wildcard ~/Library/Android/sdk/ndk-bundle/toolchains/llvm/prebuilt/darwin-x86_64/$(arch)-linux-android/bin) -target $(arch)-pc-linux-gnu --sysroot $(CURDIR)/$(output)/sysroot

cycc := $(llvm)/clang $(more)
cycp := $(llvm)/clang++ $(more) -stdlib=libc++ -isystem $(output)/sysroot/usr/lib/llvm-8/include/c++/v1

$(output)/sysroot:
	env/sysroot.sh

linker += $(output)/sysroot

endif

lflags += -pthread
