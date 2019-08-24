# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


export PATH := $(CURDIR)/$(pwd)/path:$(PATH)

.PHONY:
all:

uname := $(shell uname -s)
-include $(pwd)/uname-$(uname).mk

version := $(shell $(pwd)/version.sh)
monotonic := $(word 1,$(version))
revision := $(word 2,$(version))
package := $(word 3,$(version))
version := $(word 4,$(version))

archs := 
each = $(call loop,_,$(archs))

cflags := 
qflags := 
lflags := 
wflags := 

source := 
linked := 
header := 
sysroot := 

output := out-$(target)
archive := 

qflags += -gfull -Os

cflags += -Wall
cflags += -Werror

cflags += -fmessage-length=0
cflags += -ferror-limit=0
cflags += -ftemplate-backtrace-limit=0

beta := false

include ../default.mk
-include ../identity.mk

ifeq ($(filter nostrip,$(debug)),)
lflags += -Wl,-s
endif

include $(pwd)/target-$(target).mk

cflags += -I@/usr/include

define _
cflags/$(1) := -I$(output)/$(1)/usr/include
cc/$(1) := $(cc) $(more/$(1))
cxx/$(1) := $(cxx) $(more/$(1))
objc/$(1) := $(objc) $(more/$(1))
endef
$(each)

define depend
$(foreach arch,$(archs),$(eval $(output)/$(arch)/$(1): $(patsubst @/%,$(output)/$(arch)/%,$(2))))
endef
$(each)

define preamble
$(eval temp := $(subst /,$(space),$*))
$(eval arch := $(firstword $(temp)))
$(eval folder := $(subst $(space),/,$(wordlist 2,$(words $(temp)),$(temp))))
endef
specific = $(eval $(value preamble))
