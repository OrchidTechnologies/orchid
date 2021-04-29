# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


ifeq ($(target),win)
w_c_ares := --with-random=
else
w_c_ares := --with-random=/dev/urandom
endif

$(output)/%/$(pwd)/c-ares/include/ares_build.h: $(output)/%/$(pwd)/c-ares/Makefile
	touch $@
	$(MAKE) -C $(dir $@)
$(output)/%/$(pwd)/c-ares/src/lib/.libs/libcares.a: $(output)/%/$(pwd)/c-ares/include/ares_build.h
	$(MAKE) -C $(patsubst %/include/ares_build.h,%,$<)/src

cflags += -I@/$(pwd)/c-ares/include
header += @/$(pwd)/c-ares/include/ares_build.h
linked += $(pwd)/c-ares/src/lib/.libs/libcares.a
cflags += -I$(pwd)/c-ares/include
cflags += -DCARES_STATICLIB
