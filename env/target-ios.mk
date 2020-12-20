# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


archs += armv7
openssl/armv7 := ios-xcrun
host/armv7 := arm-apple-darwin
triple/armv7 := armv7-apple-ios
meson/armv7 := arm

archs += arm64
openssl/arm64 := ios64-xcrun
host/arm64 := aarch64-apple-darwin
triple/arm64 := aarch64-apple-ios
meson/arm64 := aarch64

sdk := iphoneos
runtime := ios
more := -miphoneos-version-min=11.0
include $(pwd)/target-apl.mk

default := arm64
support := iPhoneOS
xcframework := ios-armv7_arm64

contents := 
resources := 
versions := 
