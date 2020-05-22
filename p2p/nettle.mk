# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd/nettle := $(pwd)/nettle

p_nettle += -I@/$(pwd/gmp)
l_nettle += -L@/$(pwd/gmp)/.libs

$(call depend,$(pwd/nettle)/Makefile,@/$(pwd/gmp)/.libs/$(pre)gmp.$(lib))

$(output)/%/$(pwd/nettle)/libnettle.a $(output)/%/$(pwd/nettle)/libhogweed.a: $(output)/%/$(pwd/nettle)/Makefile
	$(MAKE) -C $(output)/$*/$(pwd/nettle) libnettle.a libhogweed.a

linked += $(pwd/nettle)/libnettle.a
linked += $(pwd/nettle)/libhogweed.a

export NETTLE_STATIC := 1

define _
# XXX: move to min-nettle and use an extra folder for -I
export NETTLE_$(subst -,_,$(1)) := -I$(CURDIR)/$(pwd) -I$(CURDIR)/$(output)/$(1)/$(pwd) -I$(CURDIR)/$(output)/$(1)/$(pwd/gmp) -I$(CURDIR)/$(output)/$(1)/$(pwd/nettle) -L$(CURDIR)/$(output)/$(1)/$(pwd/gmp)/.libs -L$(CURDIR)/$(output)/$(1)/$(pwd/nettle) -lnettle -lhogweed
endef
$(each)
