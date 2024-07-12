# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd/env := $(pwd)

xflags += -nostdinc++
lflags += -nostdlib++

xflags += -isystem $(CURDIR)/$(pwd)/libcxx/include
xflags += -isystem $(CURDIR)/$(pwd)/libcxxabi/include
xflags += -isystem $(CURDIR)/$(pwd)/extra

cflags/$(pwd)/libcxx/ += -I$(CURDIR)/$(pwd/env)/libcxx/src
cflags/$(pwd)/libcxxabi/ += -I$(CURDIR)/$(pwd/env)/libcxx/src

source += $(wildcard $(pwd)/libcxx/src/*.cpp)
source += $(wildcard $(pwd)/libcxx/src/ryu/*.cpp)

qflags += -D_LIBCPP_DISABLE_VISIBILITY_ANNOTATIONS
qflags += -D_LIBCXXABI_DISABLE_VISIBILITY_ANNOTATIONS

cflags/$(pwd)/libcxx/ += -D_LIBCPP_BUILDING_LIBRARY=
cflags/$(pwd)/libcxxabi/ += -D_LIBCPP_ENABLE_CXX17_REMOVED_UNEXPECTED_FUNCTIONS=

ifneq ($(filter $(target),and ios mac),)
cflags/$(pwd)/libcxx/ += -D_LIBCPPABI_VERSION=15000
cflags/$(pwd)/libcxx/ += -DLIBCXX_BUILDING_LIBCXXABI
else
cflags/$(pwd)/libcxx/ += -D__GLIBCXX__
endif

source += $(pwd)/libcxxabi/src/abort_message.cpp
source += $(pwd)/libcxxabi/src/cxa_demangle.cpp
source += $(pwd)/libcxxabi/src/cxa_guard.cpp
source += $(pwd)/libcxxabi/src/cxa_virtual.cpp

ifeq ($(target),win)
source += $(pwd)/libcxx/src/support/win32/locale_win32.cpp
source += $(pwd)/libcxx/src/support/win32/support.cpp
source += $(pwd)/libcxx/src/support/win32/thread_win32.cpp
else
# this requires _LIBCXXABI_WEAK to be defined
source += $(pwd)/libcxxabi/src/cxa_thread_atexit.cpp
endif
