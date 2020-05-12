# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd/openssl := $(pwd)/openssl

$(output)/%/openssl/Makefile $(subst @,%,$(patsubst %,$(output)/@/openssl/include/openssl/%.h,opensslconf opensslv)): $(pwd/openssl)/Configure $(pwd/openssl)/include/openssl/opensslv.h $(sysroot)
	rm -rf $(output)/$*/openssl
	mkdir -p $(output)/$*/openssl
	cd $(output)/$*/openssl && PATH=$(dir $(word 1,$(cc))):$${PATH} $(CURDIR)/$(pwd/openssl)/Configure $(openssl/$*) \
	    no-dso \
	    no-engine \
	    no-shared \
	    no-stdio \
	    no-ui-console \
	    no-unit-test \
	    no-weak-ssl-ciphers \
	    CC="$(cc) $(more/$*)" CFLAGS="$(qflags)" RANLIB="$(ranlib/$*)" AR="$(ar/$*)"
	$(MAKE) -C $(output)/$*/openssl include/openssl/opensslconf.h
	# XXX: this is needed because the rust openssl-sys package only accepts a single include folder
	cp -f $(pwd/openssl)/include/openssl/opensslv.h $(output)/$*/openssl/include/openssl

$(output)/%/openssl/libssl.a $(output)/%/openssl/libcrypto.a: $(output)/%/openssl/Makefile $(sysroot)
	PATH=$(dir $(word 1,$(cc))):$${PATH} $(MAKE) -C $(output)/$*/openssl build_libs

cflags += -I$(pwd)/openssl/include
cflags += -I$(pwd)/openssl/test/ossl_shim/include
cflags += -I@/openssl/include
linked += openssl/libssl.a
linked += openssl/libcrypto.a
header += @/openssl/include/openssl/opensslconf.h

define _
export $(subst -,_,$(call uc,$(triple/$(1))))_OPENSSL_LIB_DIR := $(CURDIR)/$(output)/$(1)/openssl
export $(subst -,_,$(call uc,$(triple/$(1))))_OPENSSL_INCLUDE_DIR := $(CURDIR)/$(output)/$(1)/openssl/include
endef
$(each)
