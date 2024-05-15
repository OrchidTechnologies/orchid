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


$(output)/capnproto/Makefile: $(pwd)/capnproto/c++/configure
	mkdir -p $(dir $@)
	cd $(dir $@) && $(CURDIR)/$< --enable-static \
	    CC='clang -m$(bits/$(machine))' CXX='clang++ -m$(bits/$(machine))'

export PATH := $(CURDIR)/$(output)/capnproto:$(PATH)

capnp := $(output)/capnproto/capnp

$(capnp): $(output)/capnproto/Makefile
	$(MAKE) -C $(dir $<)

$(output)/capnp/%.capnp.h: %.capnp $(capnp)
	@mkdir -p $(output)/capnp
	capnp compile \
	    -I$(pwd)/capnproto/c++/src \
	    -I$(pwd)/workerd/src \
	    $< -oc++:$(output)/capnp

cflags += -I$(pwd)/capnproto/c++/src
cflags += -I$(output)/capnp/capnproto/c++/src

source += $(shell find $(pwd)/capnproto/c++/src/kj -name '*.c++' -not -name '*test.c++')
