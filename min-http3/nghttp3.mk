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


w_nghttp3 += --enable-lib-only

nghttp3 := 
nghttp3 += $(pwd)/nghttp3/lib/.libs/libnghttp3.a

$(output)/%/$(pwd)/nghttp3/lib/includes/nghttp3/version.h $(subst @,%,$(patsubst %,$(output)/@/%,$(nghttp3))): $(output)/%/$(pwd)/nghttp3/Makefile
	$(MAKE) -C $(dir $<)

cflags += -I@/$(pwd)/nghttp3/lib/includes
cflags += -I$(pwd)/nghttp3/lib/includes

header += @/$(pwd)/nghttp3/lib/includes/nghttp3/version.h

linked += $(nghttp3)
