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

aver := 21

arch := armv7a
ossl := android-arm
alib := armeabi-v7a
mfam := arm

#arch := aarch64
#ossl := android-arm64
#alib := arm64-v8a
#mfam := aarch64

#arch := i686
#ossl := android-x86
#alib := x86
#mfam := x86

#arch := x86_64
#ossl := android-x86_64
#alib := x86_64
#mfam := x86_64

include $(pwd)/target-ndk.mk
include $(pwd)/target-gnu.mk

host := $(arch)-linux-android$(asuf)

more := 
more += -target $(arch)-unknown-linux-android$(asuf)$(aver)
more += --sysroot=$(llvm)/sysroot

# https://github.com/android-ndk/ndk/issues/884
more += -fno-addrsig

cycc := $(llvm)/bin/clang $(more)
cycp := $(llvm)/bin/clang++ $(more) -stdlib=libc++

#dotidy := yes

lflags += -Wl,--icf=all
lflags += -lm -llog
lflags += -static-libstdc++
lflags += -Wl,--no-undefined
qflags += -fPIC
