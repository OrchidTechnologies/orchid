# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


w_libevent := 
w_libevent += --disable-libevent-regress
w_libevent += --disable-openssl
w_libevent += --disable-samples

m_libevent := sed -i -e 's/libext=lib/libext=a/' libtool

libevent := 
libevent += libevent_core.a
libevent += libevent_extra.a
libevent := $(patsubst %,$(pwd)/libevent/.libs/%,$(libevent))

$(output)/%/$(pwd)/libevent/include/event2/event-config.h \
$(subst @,%,$(patsubst %,$(output)/@/%,$(libevent))) \
: $(output)/%/$(pwd)/libevent/Makefile $(sysroot)
	$(MAKE) -C $(dir $<)

cflags += -I$(pwd)/libevent/include
cflags += -I@/$(pwd)/libevent/include

linked += $(libevent)
