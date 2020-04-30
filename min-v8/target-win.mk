# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


v8src += $(pwd)/v8/src/base/debug/stack_trace_win.cc
v8src += $(pwd)/v8/src/base/platform/platform-win32.cc
v8src += $(pwd)/v8/src/diagnostics/unwinding-info-win64.cc
v8src += $(pwd)/v8/src/trap-handler/handler-inside-win.cc
v8src += $(pwd)/v8/src/trap-handler/handler-outside-win.cc

cflags/$(pwd)/v8/src/base/platform/platform-win32.cc := -U__MINGW32__ -DPAGE_TARGETS_INVALID=0x40000000
cflags/$(pwd)/v8/src/./base/platform/time.cc := -include $(pwd)/time.hpp
cflags/$(pwd)/v8/src/diagnostics/unwinding-info-win64.cc := -U_WIN32_WINNT -D_WIN32_WINNT=0x0602

cflags += -include $(pwd)/extra.hpp
lflags += -ldbghelp
