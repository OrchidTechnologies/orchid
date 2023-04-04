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
qflags += -D_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS

cflags/$(pwd)/libcxx/ += -D_LIBCPP_BUILDING_LIBRARY=
cflags/$(pwd)/libcxxabi/ += -D_LIBCPP_ENABLE_CXX17_REMOVED_UNEXPECTED_FUNCTIONS=

cflags/$(pwd)/libcxx/ += -D__GLIBCXX__

cflags/$(pwd)/libcxx/src/exception.cpp += -Wno-\#warnings
cflags/$(pwd)/libcxxabi/src/cxa_thread_atexit.cpp += -Wno-pointer-bool-conversion

source += env/libcxxabi/src/abort_message.cpp
source += env/libcxxabi/src/cxa_demangle.cpp
source += env/libcxxabi/src/cxa_guard.cpp
source += env/libcxxabi/src/cxa_virtual.cpp

ifneq ($(target),win)
# this requires _LIBCXXABI_WEAK to be defined
source += env/libcxxabi/src/cxa_thread_atexit.cpp
endif
