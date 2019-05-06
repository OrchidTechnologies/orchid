# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


cflags += -D__Userspace_os_Windows

cflags += -DWEBRTC_WIN

cflags += -DMINGW_HAS_SECURE_API

cflags += -DHAVE_WINSOCK2_H

cflags += -DABSL_FORCE_THREAD_IDENTITY_MODE=ABSL_THREAD_IDENTITY_MODE_USE_TLS

# XXX: technically for boost
lflags += -lmswsock

lflags += -liphlpapi
lflags += -lpsapi
lflags += -lsecur32
lflags += -lshlwapi
lflags += -lwinmm
lflags += -lws2_32

c_logging += -Wno-undef
c_checks += -Wno-format

c_platform_thread_types += -include $(pwd)/setname.hpp
c_thread_identity += -include pthread.h

source += $(pwd)/webrtc/rtc_base/synchronization/rw_lock_win.cc
source += $(pwd)/webrtc/rtc_base/system/file_wrapper.cc
source += $(pwd)/webrtc/rtc_base/win32.cc
