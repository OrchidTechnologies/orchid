# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd := ./$(patsubst %/,%,$(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

$(output)/%/Makefile $(output)/%/include/openssl/opensslconf.h: pwd := $(pwd)
$(output)/%/Makefile $(output)/%/include/openssl/opensslconf.h: $(pwd)/%/Configure $(linker)
	rm -rf $(output)/openssl
	mkdir -p $(output)/openssl
	cd $(output)/openssl && $(environ) $(CURDIR)/$(pwd)/openssl/Configure $(ossl) \
	    no-dso \
	    no-engine \
	    no-shared \
	    no-stdio \
	    no-ui-console \
	    no-unit-test \
	    no-weak-ssl-ciphers \
	    CC="$(cycc)" CFLAGS="$(qflags)" RANLIB="$(ranlib)" AR="$(ar)"
	$(environ) $(MAKE) -C $(output)/openssl include/openssl/opensslconf.h

$(output)/%/libssl.a $(output)/%/libcrypto.a: $(output)/%/Makefile $(linker)
	$(environ) $(MAKE) -C $(output)/openssl build_libs

cflags += -I$(pwd)/openssl/include
cflags += -I$(output)/openssl/include
linked += $(output)/openssl/libssl.a
linked += $(output)/openssl/libcrypto.a
header += $(output)/openssl/include/openssl/opensslconf.h
