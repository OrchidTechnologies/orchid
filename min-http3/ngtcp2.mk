# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# GNU Affero General Public License, Version 3 {{{ */
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# }}}


w_ngtcp2 += --enable-lib-only

w_ngtcp2 += --without-libev
w_ngtcp2 += --without-openssl
w_ngtcp2 += --with-boringssl

define _
$(output)/$(1)/$(pwd)/ngtcp2/Makefile: $(output)/$(1)/$(pwd/boringssl)/cmake/libssl.a
endef
$(each)

ngtcp2 := 
ngtcp2 += $(pwd)/ngtcp2/lib/.libs/libngtcp2.a
ngtcp2 += $(pwd)/ngtcp2/crypto/boringssl/libngtcp2_crypto_boringssl.a

$(output)/%/$(pwd)/ngtcp2/lib/includes/ngtcp2/version.h $(subst @,%,$(patsubst %,$(output)/@/%,$(ngtcp2))): $(output)/%/$(pwd)/ngtcp2/Makefile
	$(MAKE) -C $(dir $<)

cflags += -I$(pwd)/ngtcp2/crypto/includes

cflags += -I@/$(pwd)/ngtcp2/lib/includes
cflags += -I$(pwd)/ngtcp2/lib/includes

header += @/$(pwd)/ngtcp2/lib/includes/ngtcp2/version.h

linked += $(ngtcp2)
