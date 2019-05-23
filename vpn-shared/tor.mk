# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


config := 
config += --disable-asciidoc
config += --disable-system-torrc
config += --disable-unittests

cfgc := 
cfgl := 

cfgc += -I$(CURDIR)/$(pwd)/libevent/include
cfgc += -I$(CURDIR)/$(output)/libevent/include
cfgl += -L$(CURDIR)/$(output)/libevent/.libs
config += tor_cv_library_libevent_dir="(system)"

cfgc += -I$(CURDIR)/$(pwd)/p2p/rtc/openssl/include
cfgc += -I$(CURDIR)/$(output)/openssl/include
cfgl += -L$(CURDIR)/$(output)/openssl
config += tor_cv_library_openssl_dir="(system)"

config += CPPFLAGS="$(cfgc)" LDFLAGS="$(wflags) $(cfgl)"

tor := 
tor += core/libtor-app.$(lib)
tor += lib/libtor-buf.a
tor += lib/libtor-compress.a
tor += lib/libtor-container.a
tor += lib/libtor-crypt-ops.a
tor += lib/libtor-ctime.a
tor += lib/libtor-dispatch.a
tor += lib/libtor-encoding.a
tor += lib/libtor-err.a
tor += lib/libtor-evloop.a
tor += lib/libtor-fdio.a
tor += lib/libtor-fs.a
tor += lib/libtor-geoip.a
tor += lib/libtor-intmath.a
tor += lib/libtor-lock.a
tor += lib/libtor-log.a
tor += lib/libtor-malloc.a
tor += lib/libtor-math.a
tor += lib/libtor-memarea.a
tor += lib/libtor-meminfo.a
tor += lib/libtor-net.a
tor += lib/libtor-osinfo.a
tor += lib/libtor-process.a
tor += lib/libtor-pubsub.a
tor += lib/libtor-sandbox.a
tor += lib/libtor-smartlist-core.a
tor += lib/libtor-string.a
tor += lib/libtor-term.a
tor += lib/libtor-thread.a
tor += lib/libtor-time.a
tor += lib/libtor-tls.a
tor += lib/libtor-trace.a
tor += lib/libtor-version.a
tor += lib/libtor-wallclock.a
tor += lib/libcurve25519_donna.$(lib)
tor += trunnel/libor-trunnel.$(lib)
tor += ext/ed25519/donna/libed25519_donna.$(lib)
tor += ext/ed25519/ref10/libed25519_ref10.$(lib)
tor += ext/keccak-tiny/libkeccak-tiny.$(lib)
tor := $(patsubst %,$(output)/tor/src/%,$(tor))

parts := 
parts += $(output)/openssl/include/openssl/opensslconf.h
parts += $(output)/openssl/libssl.a
parts += $(output)/openssl/libcrypto.a
parts += $(output)/libevent/include/event2/event-config.h
parts += $(output)/libevent/.libs/libevent_core.a

$(pwd)/tor/configure: pwd := $(pwd)
$(pwd)/tor/configure: $(pwd)/tor/configure.ac
	cd $(pwd)/tor && ../env/autogen.sh

$(output)/tor/Makefile: cycc := $(cycc)
$(output)/tor/Makefile: pwd := $(pwd)
$(output)/tor/Makefile: $(pwd)/tor/configure $(linker) $(parts)
	rm -rf $(output)/tor
	mkdir -p $(output)/tor
	cd $(output)/tor && $(export) ../../$(pwd)/tor/configure --host=$(host) --prefix=$(out)/usr --disable-tool-name-check \
	    CC="$(cycc)" CFLAGS="$(qflags)" RANLIB="$(ranlib)" AR="$(ar)" PKG_CONFIG="$(CURDIR)/env/pkg-config" $(config)

$(tor): output := $(output)
$(tor): pwd := $(pwd)
$(tor): $(output)/tor/Makefile $(linker) $(output)/openssl/libssl.a $(output)/openssl/libcrypto.a $(pwd)/tor.sym $(shell find $(pwd)/tor -name '*.c')
	$(export) $(MAKE) -C $(output)/tor

cflags += -I$(pwd)/tor/src
lflags += -lz
linked += $(tor)
