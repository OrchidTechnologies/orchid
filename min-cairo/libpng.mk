# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


p_libpng := -I$(CURDIR)/$(pwd)/zlb/libz
l_libpng := -L@/$(pwd)/zlb

libpng := $(pwd)/libpng/.libs/libpng16.a

$(call depend,$(pwd)/libpng/Makefile,@/$(pwd)/zlb/libz.a)

$(output)/%/$(pwd)/zlb/libz.a: $(output)/%/$(pwd)/zlb/libz/_.a
	ln -sf libz/_.a $@

$(output)/%/$(libpng): $(output)/%/$(pwd)/libpng/Makefile $(sysroot)
	$(MAKE) -C $(dir $<)
	@touch $@

linked += $(libpng)
