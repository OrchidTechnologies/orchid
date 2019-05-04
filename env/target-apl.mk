# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


dll := dylib
exe := 

lflags += -Wl,-dead_strip
lflags += -Wl,-no_dead_strip_inits_and_terms

signature := /_CodeSignature/CodeResources

more += $(patsubst %,-arch %,$(arch))
more += -isysroot $(shell $(xcode) xcodebuild -sdk $(sdk) -version Path)

ifneq ($(sdk),macosx)
more += -idirafter $(shell $(xcode) xcodebuild -sdk macosx -version Path)/usr/include
endif

cycc := $(shell $(xcode) xcrun -f clang) $(more)
cycp := $(shell $(xcode) xcrun -f clang++) $(more)

ranlib := $(xcode) ranlib
