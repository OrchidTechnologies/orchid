# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


include $(pwd)/target-lnx.mk

ndk := $(wildcard ~/Library/Android/sdk/ndk-bundle)

arch := x86_64
host := $(arch)-linux-android

cycc := $(ndk)/toolchains/llvm/prebuilt/darwin-x86_64/bin/x86_64-linux-android28-clang
cycp := $(ndk)/toolchains/llvm/prebuilt/darwin-x86_64/bin/x86_64-linux-android28-clang++

cflags += -fdata-sections -ffunction-sections
lflags += -Wl,--gc-sections

lflags += -lm -llog

ranlib := $(ndk)/toolchains/llvm/prebuilt/darwin-x86_64/bin/x86_64-linux-android-ranlib
