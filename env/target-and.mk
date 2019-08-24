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

meson := linux

archs += armeabi-v7a
openssl/armeabi-v7a := android-arm
host/armeabi-v7a := armv7a-linux-androideabi
meson/armeabi-v7a := arm
flutter/armeabi-v7a := arm

archs += arm64-v8a
openssl/arm64-v8a := android-arm64
host/arm64-v8a := aarch64-linux-android
meson/arm64-v8a := aarch64
flutter/arm64-v8a := arm64

archs += x86
openssl/x86 := android-x86
host/x86 := i686-linux-android
meson/x86 := x86

archs += x86_64
openssl/x86_64 := android-x86_64
host/x86_64 := x86_64-linux-android
meson/x86_64 := x86_64

include $(pwd)/target-gnu.mk

aver := 21

define _
temp := $(subst -,$(space),$(host/$(1)))
arch := $$(word 1,$$(temp))
temp := $$(subst $$(space),-,$$(wordlist 2,3,$$(temp)))
more/$(1) := -target $$(arch)-unknown-$$(temp)$(aver)
temp := $(word 1,$(meson/$(1)))-$$(temp)
endef
$(each)

more = --sysroot=$(llvm)/sysroot
# https://github.com/android-ndk/ndk/issues/884
more += -fno-addrsig
include $(pwd)/target-ndk.mk
cxx += -stdlib=libc++

define _
ranlib/$(1) := $(llvm)/bin/$$(temp)-ranlib
ar/$(1) := $(llvm)/bin/$$(temp)-ar
strip/$(1) := $(llvm)/bin/$$(temp)-strip
endef
$(each)

# XXX: the 32-bit linker is gold
# XXX: the 64-bit linker is just ld
#lflags += -Wl,--icf=all

lflags += -lm -llog
lflags += -static-libstdc++
lflags += -Wl,--no-undefined
qflags += -fPIC
