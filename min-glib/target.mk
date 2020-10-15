# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


# glib {{{
w_glib := 
w_glib += -Dlibmount=false
w_glib += -Diconv=gnu

m_glib := 

m_glib += sed -i -e ' \
    s@-Werror=format=2@-Werror=format@g; \
' build.ninja;

m_glib += sed -i -e ' \
    s@^G_BEGIN_DECLS$$@\#define G_INTL_STATIC_COMPILATION 1'$$'\\\n''G_BEGIN_DECLS@; \
' glib/glibconfig.h;

glib := 
glib += gmodule/libgmodule-2.0.a
glib += glib/libglib-2.0.a
ifneq ($(target),lnx)
glib += subprojects/proxy-libintl/libintl.a
endif
temp := $(patsubst %,$(pwd)/glib/%,$(glib))

$(call depend,$(pwd)/glib/build.ninja,@/usr/include/iconv.h @/usr/lib/libiconv.a)
$(call depend,$(pwd)/glib/glib/glibconfig.h,@/$(pwd)/glib/build.ninja)

$(subst @,%,$(patsubst %,$(output)/@/%,$(temp))): $(output)/%/$(pwd)/glib/build.ninja
	cd $(dir $<) && ninja $(glib) && touch $(glib)

linked += $(temp)

header += @/$(pwd)/glib/build.ninja
cflags += -I@/$(pwd)/glib/glib

cflags += -I$(pwd)/glib
cflags += -I$(pwd)/glib/glib
cflags += -I$(pwd)/glib/gmodule

#cflags += -I@/$(pwd)/glib
#glib += gio/libgio-2.0.a
# }}}
# libiconv {{{
w_libiconv := LDFLAGS="$(wflags)"

export GNULIB_SRCDIR := $(CURDIR)/$(pwd)/gnulib
export GNULIB_TOOL := $(GNULIB_SRCDIR)/gnulib-tool

linked += usr/lib/libiconv.a
header += @/usr/include/iconv.h

define _
$(output)/$(1)/usr/include/%.h $(output)/$(1)/usr/lib/lib%.a: $(output)/$(1)/$(pwd)/lib%/Makefile $(sysroot)
	$(MAKE) -C $$(dir $$<) install
endef
$(each)
# }}}
