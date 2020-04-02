# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2019  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


archs += i386
openssl/i386 := darwin-i386-cc
host/i386 := i386-apple-darwin
meson/i386 := x86

archs += x86_64
openssl/x86_64 := darwin64-x86_64-cc
host/x86_64 := x86_64-apple-darwin
meson/x86_64 := x86_64

sdk := macosx
runtime := osx
more := -mmacosx-version-min=10.14
include $(pwd)/target-apl.mk

default := x86_64

contents := /Contents
resources := /Resources
versions := /Versions/A
