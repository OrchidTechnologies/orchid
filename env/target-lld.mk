# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


# XXX: ring needs to update to a newer version of cc-rs
# https://github.com/briansmith/ring/issues/2126
# XXX: this also runs into some issue with --gc-sections
ifneq ($(meson),darwin)
include $(pwd)/target-gnu.mk
endif

wflags += -fuse-ld=lld
lflags += -Wl,--error-limit=0

ifeq ($(filter nostrip,$(debug)),)
lflags += -Wl,--icf=all
else
lflags += -Wl,--icf=none
endif

export LLD_VERSION := Linker: LLD
