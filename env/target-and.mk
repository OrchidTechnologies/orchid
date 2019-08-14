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
#mfam := aarch64

#ossl := android-mips
#mfam := mips

#ossl := android-mip64
#mfam := mips64

#ossl := android-x86
#mfam := x86

#arch := x86_64
#ossl := android-x86_64
#mfam := x86_64

include $(pwd)/target-ndk.mk

host := $(arch)-linux-android$(asuf)

more := 

cycc := $(llvm)/bin/$(arch)-linux-android$(asuf)$(aver)-clang $(more)
cycp := $(llvm)/bin/$(arch)-linux-android$(asuf)$(aver)-clang++ $(more)

#dotidy := yes
tflags += -target $(arch)-unknown-linux-android$(asuf)$(aver)
tflags += -I$(llvm)/sysroot/usr/include/c++/v1
tflags += -I$(llvm)/sysroot/usr/local/include
tflags += -I$(llvm)/lib64/clang/8.0.2/include
tflags += -I$(llvm)/sysroot/usr/include/arm-linux-androideabi
tflags += -I$(llvm)/sysroot/usr/include

lflags += -lm -llog
lflags += -static-libstdc++
lflags += -Wl,--no-undefined
qflags += -fPIC
