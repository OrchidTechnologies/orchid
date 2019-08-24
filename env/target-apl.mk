# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


dll := dylib
lib := a
exe := 

meson := darwin

lflags += -Wl,-dead_strip
lflags += -Wl,-no_dead_strip_inits_and_terms

signature := /_CodeSignature/CodeResources

more += -isysroot $(shell xcrun --sdk $(sdk) --show-sdk-path)

ifneq ($(sdk),macosx)
more += -idirafter $(shell xcrun --sdk macosx --show-sdk-path)/usr/include
endif

define _
more/$(1) := -arch $(1)
endef
$(each)

clang := $(shell xcrun -f clang)

objc := $(clang) $(more)

ifeq ($(filter iosndk,$(debug)),)
debug += notidy
cc := $(clang) $(more)
cxx := $(shell xcrun -f clang++) $(more)
else

define _
more/$(1) += -target $(host/$(1))18.5.0
endef
$(each)

resource := $(shell $(clang) -print-resource-dir)
more += -resource-dir $(resource)
lflags += $(resource)/lib/darwin/libclang_rt.$(runtime).a

more += -B$(dir $(clang))
more += -fno-strict-return
include $(pwd)/target-ndk.mk
cxx += -stdlib=libc++

endif

define _
ranlib/$(1) := ranlib
ar/$(1) := ar
strip/$(1) := strip
endef
$(each)
