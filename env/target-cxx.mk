# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


xflags += -nostdinc++
xflags += -isystem $(CURDIR)/$(pwd)/libcxx/include
xflags += -isystem $(CURDIR)/$(pwd)/libcxxabi/include

source += $(wildcard $(pwd)/libcxx/src/*.cpp)
cflags/$(pwd)/libcxx/ += -D_LIBCPP_BUILDING_LIBRARY
cflags/$(pwd)/libcxx/ += -D__GLIBCXX__

qflags += -D_LIBCPP_DISABLE_AVAILABILITY
qflags += -D_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS
