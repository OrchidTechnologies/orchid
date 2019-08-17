# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


ifeq ($(ANDROID_HOME),)
export ANDROID_HOME := $(wildcard ~/Library/Android/sdk)
endif

ndk := $(ANDROID_NDK_HOME)

ifeq ($(ndk),)
ndk := $(wildcard $(ANDROID_HOME)/ndk-bundle)
endif

ifeq ($(ndk),)
ndk := $(wildcard /usr/local/share/android-ndk)
endif

ifeq ($(ndk),)
$(error install Android NDK and export ANDROID_NDK_HOME)
endif

ifeq ($(ANDROID_NDK_HOME),)
environ += ANDROID_NDK_HOME=$(ndk)
endif

llvm := $(ndk)/toolchains/llvm/prebuilt/darwin-x86_64

environ += PATH='$(llvm)/bin:$(PATH)'

ifeq ($(arch),armv7a)
asuf := eabi
apre := arm
else
asuf := 
apre := $(arch)
endif

ranlib := $(llvm)/bin/$(apre)-linux-android$(asuf)-ranlib
ar := $(llvm)/bin/$(apre)-linux-android$(asuf)-ar
strip := $(llvm)/bin/$(apre)-linux-android$(asuf)-strip

include $(pwd)/target-gnu.mk
