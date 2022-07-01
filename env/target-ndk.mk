# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


# XXX: consider checking ANDROID_SDK_ROOT

ifeq ($(ANDROID_HOME),)
export ANDROID_HOME := $(wildcard ~/Library/Android/sdk)
endif

ifeq ($(ANDROID_HOME),)
export ANDROID_HOME := $(wildcard /usr/local/lib/android/sdk)
endif

ifeq ($(ANDROID_HOME),)
export ANDROID_HOME := $(wildcard /usr/lib/android-sdk)
endif

ifeq ($(ANDROID_HOME),)
ifneq ($(shell which cygpath 2>/dev/null),)
export ANDROID_HOME := $(wildcard $(shell cygpath '$(USERPROFILE)')/AppData/Local/Android/Sdk)
endif
endif

ndk := $(ANDROID_NDK_HOME)

ifneq ($(ANDROID_HOME),)
ifeq ($(ndk),)
ndk := $(wildcard $(ANDROID_HOME)/ndk-bundle)
endif

ifeq ($(ndk),)
ndk := $(shell ls $(ANDROID_HOME)/ndk 2>/dev/null | sort -nr | head -n1)
ifneq ($(ndk),)
ndk := $(ANDROID_HOME)/ndk/$(ndk)
endif
endif
endif

ifeq ($(ndk),)
ndk := $(wildcard /usr/local/share/android-ndk)
endif

ifeq ($(ndk),)
ndk := $(wildcard /usr/lib/android-ndk)
endif

ifeq ($(ndk),)
$(error install Android NDK and export ANDROID_NDK_HOME)
endif

ifeq ($(ANDROID_NDK_HOME),)
export ANDROID_NDK_HOME := $(ndk)
endif

llvm := $(ndk)/toolchains/llvm/prebuilt/$(prebuilt)
#export PATH := $(PATH):$(llvm)/bin

cc := $(llvm)/bin/clang $(more)
cxx := $(llvm)/bin/clang++ $(more)

tidy := $(llvm)/bin/clang-tidy

$(shell rm -f $(output)/ndk && mkdir -p $(output) && ln -sf $(llvm) $(output)/ndk)
qflags += -fdebug-prefix-map=$(llvm)=$(output)/ndk
