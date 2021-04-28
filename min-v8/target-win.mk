# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


vflags += -DV8_TARGET_OS_WIN

v8src += $(filter %_win.cc %-win.cc %-win64.cc,$(v8all))
v8src += $(pwd/v8)/src/base/platform/platform-win32.cc

v8src := $(filter-out %/trace-writer.cc,$(v8src))

cflags/$(pwd/v8)/src/base/platform/platform-win32.cc += -U__MINGW32__ -DPAGE_TARGETS_INVALID=0x40000000
cflags/$(pwd/v8)/src/./base/platform/time.cc += -include $(pwd/v8)/../time.hpp
cflags/$(pwd/v8)/src/diagnostics/unwinding-info-win64.cc += -U_WIN32_WINNT -D_WIN32_WINNT=0x0602

cflags/$(pwd)/v8/ += -Wno-format
cflags/$(pwd)/v8/ += -Wno-ignored-attributes

cflags += -include $(pwd/v8)/../extra.hpp
lflags += -ldbghelp
