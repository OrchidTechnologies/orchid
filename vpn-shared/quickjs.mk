# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd/quickjs := $(pwd)/quickjs

source += $(pwd/quickjs)/libregexp.c $(filter-out \
    $(shell grep -lw 'int main' $(pwd/quickjs)/*.c) \
,$(wildcard $(pwd/quickjs)/*.c))

cflags/$(pwd/quickjs)/ += -Wno-unused-but-set-variable
cflags/$(pwd/quickjs)/ += -Wno-unused-result
cflags/$(pwd/quickjs)/ += -Wno-unused-variable

# XXX: error: implicit conversion from 'long long' to 'double' changes value from 9223372036854775807 to 9223372036854775808
cflags/$(pwd/quickjs)/ += -Wno-implicit-const-int-float-conversion

cflags/$(pwd/quickjs)/ += -DCONFIG_VERSION='""'
cflags/$(pwd/quickjs)/ += -include $(pwd/quickjs)/../environ.hpp

# XXX: QuickJS doesn't support being run on multiple stacks?!
cflags/$(pwd/quickjs)/ += -DEMSCRIPTEN

ifeq ($(target),lnx)
# XXX: for sighandler_t
cflags/$(pwd/quickjs)/ += -D_GNU_SOURCE
endif
