# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


include $(pwd)/target-lld.mk

lflags += -Wl,--build-id=none
lflags += -Wl,-z,noexecstack

lflags += -Wl,--no-undefined
lflags += -Wl,-z,defs
lflags += -Wl,--no-copy-dt-needed-entries

ifeq ($(target),and)
# XXX: this is wrong in the general case
# I need a separate build for this... :(
qflags += -fpic
lflags += -fpic
else
qflags += -fpie
lflags += -fpie
endif

qflags += -fno-plt
lflags += -fno-plt

lflags += -Wl,-z,relro
lflags += -Wl,-z,now

# https://maskray.me/blog/2021-01-09-copy-relocations-canonical-plt-entries-and-protected
qflags += -fno-semantic-interposition
qflags += -fdirect-access-external-data
