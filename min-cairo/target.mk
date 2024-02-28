# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


w_cairo := 
w_cairo += $(shell sed $(pwd)/cairo/configure.ac -e '/^CAIRO_ENABLE_\(FUNCTIONS\|\(FONT\|SURFACE\)_BACKEND\)$(paren)/{s///;s/_/-/g;s/,.*//;/^\(png\)$$/!{s/^/--disable-/;p}};d')

p_cairo := 
l_cairo := 

p_cairo += -Wno-enum-conversion
p_cairo += -Wno-parentheses-equality
p_cairo += -Wno-unused-function
p_cairo += -Wno-unused-variable

p_cairo += -I$(CURDIR)/$(pwd)/zlb/libz
l_cairo += -L@/$(pwd)/zlb

p_cairo += -I$(CURDIR)/$(pwd)/libpng
p_cairo += -I@/$(pwd)/libpng
l_cairo += -L@/libpbg/.libs

p_cairo += -I$(CURDIR)/$(pwd)/pixman/pixman
p_cairo += -I@/$(pwd)/pixman/pixman
l_cairo += -L@/$(pwd)/pixman/.libs

libcairo := $(pwd)/cairo/src/.libs/libcairo.a

$(output)/%/$(pwd)/cairo/src/cairo-features.h \
$(subst @,%,$(patsubst %,$(output)/@/%,$(libcairo))) \
: $(output)/%/$(pwd)/cairo/Makefile $(sysroot)
	$(MAKE) -C $(dir $<)/src

cflags += -I$(pwd)/cairo/src
cflags += -I@/$(pwd)/cairo/src

linked += $(libcairo)

include $(pwd)/libpng.mk
include $(pwd)/pixman.mk

define _
$(output)/$(1)/$(pwd)/cairo/Makefile: $(output)/$(1)/$(libpng) $(patsubst %,$(output)/$(1)/%,$(libpixman))
endef
$(each)

$(call include,zlb/target.mk)
