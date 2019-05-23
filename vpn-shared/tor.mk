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

cfgc += -I$(CURDIR)/$(pwd)/openssl/include
cfgc += -I$(CURDIR)/$(output)/openssl/include
cfgl += -L$(CURDIR)/$(output)/openssl
config += tor_cv_library_openssl_dir="(system)"

config += CPPFLAGS="$(cfgc)" LDFLAGS="$(cfgl)"

tor := 
tor += tor/src/core/libtor-app.$(lib)
tor += tor/src/lib/libtor-*.$(lib)
tor += tor/src/trunnel/libor-trunnel.$(lib)
tor += tor/src/lib/libcurve25519_donna.$(lib)
tor += tor/src/ext/ed25519/donna/libed25519_donna.$(lib)
tor += tor/src/ext/ed25519/ref10/libed25519_ref10.$(lib)
tor += tor/src/ext/keccak-tiny/libkeccak-tiny.$(lib)
tor += openssl/libssl.$(lib)
tor += openssl/libcrypto.$(lib)
tor += libevent/.libs/libevent_core.$(lib)
tor += libevent/.libs/libevent_extra.$(lib)
tor := $(patsubst %,$(output)/%,$(tor))

parts := 
parts += $(output)/openssl/include/openssl/opensslconf.h
parts += $(output)/openssl/libssl.$(lib)
parts += $(output)/openssl/libcrypto.$(lib)
parts += $(output)/libevent/include/event2/event-config.h
parts += $(output)/libevent/.libs/libevent_core.$(lib)

$(pwd)/tor/configure: pwd := $(pwd)
$(pwd)/tor/configure: $(pwd)/tor/configure.ac
	cd $(pwd)/tor && ../env/autogen.sh

$(output)/tor/Makefile: cycc := $(cycc)
$(output)/tor/Makefile: pwd := $(pwd)
$(output)/tor/Makefile: $(pwd)/tor/configure $(linker) $(parts)
	rm -rf $(output)/tor
	mkdir -p $(output)/tor
	cd $(output)/tor && $(export) ../../$(pwd)/tor/configure --host=$(host) --prefix=$(out)/usr --disable-tool-name-check \
	    CC="$(cycc)" LDFLAGS="$(wflags)" RANLIB="$(ranlib)" PKG_CONFIG="$(CURDIR)/env/pkg-config" $(config)

$(output)/tor: output := $(output)
$(output)/tor/libtor.o: pwd := $(pwd)
$(output)/tor/libtor.o: $(output)/tor/Makefile $(linker) $(output)/openssl/libssl.a $(output)/openssl/libcrypto.a $(pwd)/tor.sym $(shell find $(pwd)/tor -name '*.c')
	$(export) $(MAKE) -C $(output)/tor
	@$(cycp) $(wflags) -o $@ $(tor) -nostdlib -Wl,-r,-s -nostdlib -exported_symbols_list $(pwd)/tor.sym
	#-Wl,-r,-flinker-output=pie,--retain-symbols-file,$(pwd)/tor.sym

cflags += -I$(pwd)/tor/src
linked += $(output)/tor/libtor.o
lflags += -lz
