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

msys := darwin

lflags += -Wl,-dead_strip
lflags += -Wl,-no_dead_strip_inits_and_terms

signature := /_CodeSignature/CodeResources

more += $(patsubst %,-arch %,$(arch))
more += -isysroot $(shell $(environ) xcodebuild -sdk $(sdk) -version Path)

ifneq ($(sdk),macosx)
more += -idirafter $(shell $(environ) xcodebuild -sdk macosx -version Path)/usr/include
endif

clang := $(shell $(environ) xcrun -f clang)
cyco := $(clang) $(more)

ifeq ($(filter iosndk,$(debug)),)
debug += notidy
cycc := $(clang) $(more)
cycp := $(shell $(environ) xcrun -f clang++) $(more)
else
include $(pwd)/target-ndk.mk
resource := $(shell $(environ) xcrun clang -print-resource-dir)
more += -target $(host)18.5.0
more += -B$(dir $(clang))
more += -Xclang -resource-dir -Xclang $(resource)
more += -fno-strict-return
cycc := $(llvm)/bin/clang $(more)
cycp := $(llvm)/bin/clang++ $(more) -stdlib=libc++
lflags += $(resource)/lib/darwin/libclang_rt.$(target).a
endif

ranlib := ranlib
ar := ar
strip := strip
