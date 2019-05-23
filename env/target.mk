# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd := ./$(patsubst %/,%,$(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))
include $(pwd)/common.mk

.PHONY:
all:

uname := $(shell uname -s)
-include $(pwd)/uname-$(uname).mk

version := $(shell $(pwd)/version.sh)
monotonic := $(word 1,$(version))
version := $(word 2,$(version))

cflags := 
qflags := 
lflags := 
wflags := 

source := 
linked := 
header := 
linker := 

export := 
output := out-$(target)

cleans := 
cleans += $(output)

qflags += -gfull -Os
lflags += -Wl,-s

cflags += -Wall
cflags += -Werror

cflags += -fmessage-length=0
cflags += -ferror-limit=0
cflags += -ftemplate-backtrace-limit=0

include ../default.mk
-include ../identity.mk

include $(pwd)/target-$(target).mk
