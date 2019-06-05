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

arch := armv7a
ossl := android-arm

#arch := aarch64
#ossl := android-arm64

#ossl := android-mips
#ossl := android-mip64
#ossl := android-x86

#arch := x86_64
#ossl := android-x86_64

host := $(arch)-linux-android

include $(pwd)/target-ndk.mk

more := 

cycc := $(llvm)/$(arch)-linux-android$(aabi)28-clang $(more)
cycp := $(llvm)/$(arch)-linux-android$(aabi)28-clang++ $(more)

lflags += -lm -llog
qflags += -fPIC
