# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


cmake := Darwin

archs += i386
openssl/i386 := darwin-i386-cc
host/i386 := i386-apple-darwin
triple/i386 := i686-apple-darwin
meson/i386 := x86
bits/i386 := 32

archs += x86_64
openssl/x86_64 := darwin64-x86_64-cc
host/x86_64 := x86_64-apple-darwin
triple/x86_64 := x86_64-apple-darwin
meson/x86_64 := x86_64
bits/x86_64 := 64

archs += arm64
openssl/arm64 := darwin64-arm64-cc
host/arm64 := arm64-apple-darwin
triple/arm64 := aarch64-apple-darwin
meson/arm64 := aarch64
bits/arm64 := 64

ifeq ($(machine),)
machine := x86_64
endif

sdk := macosx
runtime := osx
more := -mmacosx-version-min=10.15
include $(pwd)/target-apl.mk

xcframework := macos-arm64_x86_64

contents := /Contents
resources := /Resources
versions := /Versions/A
