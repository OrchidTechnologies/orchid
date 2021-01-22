# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pre := lib
dll := so
lib := a
exe := 

meson := linux

archs += armeabi-v7a
openssl/armeabi-v7a := android-arm
host/armeabi-v7a := armv7a-linux-androideabi
triple/armeabi-v7a := armv7-linux-androideabi
meson/armeabi-v7a := arm
flutter/armeabi-v7a := arm

archs += arm64-v8a
openssl/arm64-v8a := android-arm64
host/arm64-v8a := aarch64-linux-android
triple/arm64-v8a := aarch64-linux-android
meson/arm64-v8a := aarch64
flutter/arm64-v8a := arm64

archs += x86
openssl/x86 := android-x86
host/x86 := i686-linux-android
triple/x86 := i686-linux-android
meson/x86 := x86

archs += x86_64
openssl/x86_64 := android-x86_64
host/x86_64 := x86_64-linux-android
triple/x86_64 := x86_64-linux-android
meson/x86_64 := x86_64

ifeq ($(machine),)
machine := arm64-v8a
endif

include $(pwd)/target-elf.mk

aver := 21

ifeq ($(uname-o),Android)

cc := clang
cxx := clang++

openssl/arm64-v8a := linux-aarch64

define _
more/$(1) := 
ranlib/$(1) := ranlib
ar/$(1) := ar
strip/$(1) := strip
windres/$(1) := false
endef
$(each)

else

more = --sysroot=$(llvm)/sysroot
# https://github.com/android-ndk/ndk/issues/884
more += -fno-addrsig
include $(pwd)/target-ndk.mk

cxx += -stdlib=libc++
lflags += -static-libstdc++

define _
temp := $(subst -,$(space),$(host/$(1)))
arch := $$(word 1,$$(temp))
temp := $$(subst $$(space),-,$$(wordlist 2,3,$$(temp)))
more/$(1) := -target $$(arch)-unknown-$$(temp)$(aver)
temp := $(word 1,$(meson/$(1)))-$$(temp)
ranlib/$(1) := $(llvm)/bin/$$(temp)-ranlib
ar/$(1) := $(llvm)/bin/$$(temp)-ar
strip/$(1) := $(llvm)/bin/$$(temp)-strip
windres/$(1) := false
endef
$(each)

endif

lflags += -lm -llog
