# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


$(output)/zlib/Makefile: cycc := $(cycc)
$(output)/zlib/Makefile: pwd := $(pwd)
$(output)/zlib/Makefile: $(pwd)/zlib/configure $(linker) $(parts)
	rm -rf $(output)/zlib
	mkdir -p $(output)/zlib
	cd $(output)/zlib && $(environ) CC="$(cycc)" CFLAGS="$(qflags)" ../../$(pwd)/zlib/configure --static

$(output)/zlib/libz.a: output := $(output)
$(output)/zlib/libz.a: pwd := $(pwd)
$(output)/zlib/libz.a: $(output)/zlib/Makefile $(linker)
	$(environ) $(MAKE) -C $(output)/zlib libz.a RANLIB="$(ranlib)" AR="$(ar)" ARFLAGS="-r"

cflags += -I$(pwd)/zlib/include
linked += $(output)/zlib/libz.a
