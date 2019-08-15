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

$(output)/%/include/event2/event-config.h $(output)/%/.libs/libevent_core.a $(output)/%/.libs/libevent_extra.a: $(output)/%/Makefile $(sysroot)
	$(environ) $(MAKE) -C $(dir $<)

cflags += -I$(pwd)/libevent/include
cflags += -I$(output)/$(pwd)/libevent/include

linked += $(output)/$(pwd)/libevent/.libs/libevent_core.a
linked += $(output)/$(pwd)/libevent/.libs/libevent_extra.a
