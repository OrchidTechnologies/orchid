# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


cflags += -I$(pwd)/libevent/include
cflags += -I$(output)/libevent/include

$(pwd)/libevent/configure: pwd := $(pwd)
$(pwd)/libevent/configure: $(pwd)/libevent/configure.ac
	cd $(pwd)/libevent && ../env/autogen.sh

$(output)/libevent/Makefile: host := $(host)
$(output)/libevent/Makefile: cycc := $(cycc)
$(output)/libevent/Makefile: output := $(output)
$(output)/libevent/Makefile: pwd := $(pwd)
$(output)/libevent/Makefile: $(pwd)/libevent/configure $(linker)
	rm -rf $(output)/libevent
	mkdir -p $(output)/libevent
	cd $(output)/libevent && ../../$(pwd)/libevent/configure --host=$(host) \
	    CC="$(cycc)" LDFLAGS="$(wflags)" RANLIB="$(ranlib)" PKG_CONFIG="$${PWD}/../../$(pwd)/pkg-config" \
	    --enable-openssl --disable-samples --disable-libevent-regress \
	    --enable-static --disable-shared

$(output)/libevent: output := $(output)
$(output)/libevent/include/event2/event-config%h $(output)/libevent/.libs/libevent_core%$(lib): $(output)/libevent/Makefile
	$(MAKE) -C $(output)/libevent

linked += $(output)/libevent/.libs/libevent_core.$(lib)
