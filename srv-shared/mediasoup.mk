# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# GNU Affero General Public License, Version 3 {{{ */
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# }}}


cflags += -I$(pwd)/json/include/nlohmann
cflags += -I$(pwd)/json/include


source += $(wildcard $(pwd)/usrsctp/usrsctplib/*.c)
source += $(filter-out %/sctp_cc_functions.c,$(wildcard $(pwd)/usrsctp/usrsctplib/netinet/*.c))
source += $(pwd)/congestion.cc
cflags += -I$(pwd)/usrsctp
cflags += -I$(pwd)/usrsctp/usrsctplib
cflags += -I$(pwd)/sctp-idata/src

ifeq ($(target),win)
cflags/$(pwd)/usrsctp/usrsctplib/ += -Wno-unused-function
cflags/$(pwd)/congestion.cc += -Wno-unused-function
endif


$(output)/extra/mediasoup.hpp: $(pwd)/mediasoup/src/supportedRtpCapabilities.ts
	mkdir -p $(dir $@)
	sed -e '/^[^ \t{}]/d;s/};/}/;s/[ \t]//g;/^\/\//d;s/'"'"'/"/g;s/\(^\|[{,]\)\([a-zA-Z]*\):/\1"\2":/g' $< | tr -d $$'\n' | xxd -i >$@

$(call depend,$(pwd)/source/sfu.cpp.o,$(output)/extra/mediasoup.hpp)

cflags += -I$(pwd)/mediasoup/worker/include
source += $(wildcard $(pwd)/mediasoup/worker/src/*/*/*.cpp)
source += $(wildcard $(pwd)/mediasoup/worker/src/*/*.cpp)
source += $(filter-out %/main.cpp,$(wildcard $(pwd)/mediasoup/worker/src/*.cpp))

cflags += -DMS_LITTLE_ENDIAN
cflags += -DMS_LOG_STD
cflags += -DMS_LOG_TRACE
#cflags += -DMS_LOG_DEV_LEVEL=3

# XXX: this trips if MS_LOG_DEV_LEVEL isn't set
cflags/$(pwd)/mediasoup/worker/deps/libwebrtc/libwebrtc/modules/remote_bitrate_estimator/remote_bitrate_estimator_abs_send_time.cc += -Wno-unused-but-set-variable

# XXX: maybe try to upstream an #ifndef __MINGW32__
chacks/$(pwd)/mediasoup/worker/src/Utils/File.cpp += s/^\#define.*_S_.*//

source += $(shell find $(pwd)/mediasoup/worker/deps/libwebrtc/libwebrtc -name '*.cc' | LC_COLLATE=C sort)
cflags/$(pwd)/mediasoup/worker/ += -I$(pwd)/mediasoup/worker/deps/libwebrtc{/libwebrtc,}
cflags/$(pwd)/mediasoup/worker/ += -Dwebrtc=mswebrtc -Drtc=msrtc

# XXX: thread_local is crashing on Win32 and probably is unreliable everywhere anyway
cflags/$(pwd)/mediasoup/worker/ += -Dthread_local=

source += $(pwd)/mediasoup/worker/deps/netstring/netstring-c/netstring.c
cflags += -I$(pwd)/mediasoup/worker/deps/netstring/netstring-c
