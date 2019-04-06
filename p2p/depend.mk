# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

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


$(output)/orchid-lib/aleth/buildinfo.%: orchid-lib/aleth/cmake/cable/buildinfo/buildinfo.%.in
	sed -e 's/@FUNCTION_NAME@/aleth_get_buildinfo/g' $< >$@
$(output)/orchid-lib/aleth/libdevcore/Common.o: $(output)/orchid-lib/aleth/buildinfo.h

secp256k1 := ac8ccf29b8c6b2b793bc734661ce43d1f952977a

orchid-lib/secp256k1-$(secp256k1).tar.gz:
	curl -Lo $@ https://github.com/chfast/secp256k1/archive/$(secp256k1).tar.gz

orchid-lib/secp256k1: orchid-lib/secp256k1-$(secp256k1).tar.gz
	rm -rf $@
	mkdir -p $@
	tar -C orchid-lib/secp256k1 --strip-components=1 -zxvf $<

$(output)/gen_context: orchid-lib/secp256k1/src/gen_context.c
	gcc -o $@ $< -Iorchid-lib/secp256k1

orchid-lib/secp256k1/src/ecmult_static_context.h: $(output)/gen_context
	cd orchid-lib/secp256k1 && $(PWD)/$(output)/gen_context

$(output)/orchid-lib/secp256k1/src/secp256k1.o: orchid-lib/secp256k1/src/ecmult_static_context.h
