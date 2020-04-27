# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


$(output)/icu4c/Makefile: $(pwd)/icu4c/configure
	mkdir -p $(dir $@)
	cd $(dir $@) && $(CURDIR)/$<

$(output)/icu4c/bin/uconv: $(output)/icu4c/Makefile
	$(MAKE) -C $(dir $<) RM='rm -f'

$(call depend,$(pwd)/icu4c/Makefile,$(output)/icu4c/bin/uconv)

w_icu4c += --with-cross-build=$(CURDIR)/$(output)/icu4c

define icu4c
$(output)/%/$(pwd)/icu4c/lib/libicu$(1).a: $(output)/%/$(pwd)/icu4c/Makefile
	mkdir -p $$(dir $$@)
	$$(MAKE) -C $$(dir $$<)/$(2)
linked += $(pwd)/icu4c/lib/libicu$(1).a
endef

$(eval $(call icu4c,i18n,i18n))
$(eval $(call icu4c,uc,common))
$(eval $(call icu4c,data,data))

cflags += -I$(pwd)/extra/{common,i18n}
