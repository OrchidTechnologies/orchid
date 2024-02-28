# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


# XXX: this now needs to be per target (due to -m$(bits))

$(output)/icu4c/Makefile: $(pwd)/icu4c/configure
	mkdir -p $(dir $@)
	cd $(dir $@) && $(CURDIR)/$< --enable-static \
	    CC='clang -m$(bits/$(machine))' CXX='clang++ -m$(bits/$(machine))'

$(output)/icu%c/bin/uconv $(output)/icu%c/lib/libicuuc.a $(output)/icu%c/lib/libicudata.a: $(output)/icu4c/Makefile
	$(MAKE) -C $(dir $<) RM='rm -f'

$(call depend,$(pwd)/icu4c/Makefile,$(output)/icu4c/bin/uconv)

w_icu4c += --with-cross-build=$(CURDIR)/$(output)/icu4c
w_icu4c += SHELL=/bin/bash

ifeq ($(target),win)
uflags += MSYS_VERSION=
uflags += CURR_FULL_DIR=
uflags += CURR_SRCCODE_FULL_DIR=
endif

define icu4c
$(output)/%/$(pwd)/icu4c/lib/$(1).a: $(output)/%/$(pwd)/icu4c/Makefile
	@mkdir -p $$(dir $$@)
	@# XXX: -s in the hope of avoiding EGAIN during stdout flood on macOS Linux cross
	$$(MAKE) -C $$(dir $$<)/$(2) -s $(uflags)
linked += $(pwd)/icu4c/lib/$(1).a
endef

ifeq ($(target),win)
$(eval $(call icu4c,libsicuin,i18n))
$(eval $(call icu4c,libsicuuc,common))
$(eval $(call icu4c,sicudt,data))
else
$(eval $(call icu4c,libicui18n,i18n))
$(eval $(call icu4c,libicuuc,common))
$(eval $(call icu4c,libicudata,data))
endif

icu4c := -I$(pwd)/extra/{common,i18n}
cflags += $(icu4c)

cflags += -DU_STATIC_IMPLEMENTATION
