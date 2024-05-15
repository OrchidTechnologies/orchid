# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


ifeq ($(target),ios)
lflags += -lsqlite3
else
pwd/sqlite := $(pwd)/sqlite

# XXX: $(pwd)/sqlite/configure is (strangely) in the repository, but should not be rebuilt with autogen.sh
$(output)/sqlite/Makefile:
	mkdir -p $(output)/sqlite
	cd $(output)/sqlite && $(CURDIR)/$(pwd/sqlite)/configure --enable-static --disable-shared --disable-tcl

$(output)/$(pwd/sqlite)3%h $(output)/sqlite/sqlite3%c: $(output)/sqlite/Makefile
	touch $(pwd/sqlite)/manifest{,.uuid}
	rm -f $(output)/sqlite/fts5.c
	$(MAKE) -C $(output)/sqlite sqlite3.c
	rm -f $(pwd/sqlite)/manifest{,.uuid}
	mkdir -p $(dir $(output)/$(pwd/sqlite))
	cp -af $(output)/sqlite/sqlite3.h $(output)/$(pwd/sqlite)3.h

cflags += -DSQLITE_DQS=0
cflags += -DSQLITE_ENABLE_RTREE

cflags += -DSQLITE_OMIT_DEPRECATED
cflags += -DSQLITE_OMIT_LOAD_EXTENSION
cflags += -DSQLITE_OMIT_TCL_VARIABLE

source += $(output)/sqlite/sqlite3.c

cflags += -I$(output)/$(pwd)
header += $(output)/$(pwd/sqlite)3.h

cflags/./$(output)/sqlite/sqlite3.c += -Wno-unused-but-set-variable
endif
