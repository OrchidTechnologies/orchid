# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd/webrtc := $(pwd)/webrtc

source += $(pwd)/stub.cc

cflags += -I$(pwd)/extra
cflags += -I$(pwd)/webrtc

webrtc := 


webrtc += $(filter-out \
    %/create_peerconnection_factory.cc \
,$(wildcard $(pwd)/webrtc/api/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/api/crypto/*.cc)

webrtc += $(filter-out \
    %/goog_cc_factory.cc \
,$(wildcard $(pwd)/webrtc/api/transport/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/api/transport/media/*.cc)

webrtc += $(wildcard $(pwd)/webrtc/api/units/*.cc)

webrtc += $(pwd)/webrtc/api/audio_codecs/audio_encoder.cc

webrtc += $(pwd)/webrtc/api/numerics/samples_stats_counter.cc

webrtc += $(pwd)/webrtc/api/rtc_event_log/rtc_event.cc
webrtc += $(pwd)/webrtc/api/rtc_event_log/rtc_event_log.cc

webrtc += $(pwd)/webrtc/api/task_queue/task_queue_base.cc

webrtc += $(pwd)/webrtc/api/video/color_space.cc
webrtc += $(pwd)/webrtc/api/video/encoded_image.cc
webrtc += $(pwd)/webrtc/api/video/hdr_metadata.cc
webrtc += $(pwd)/webrtc/api/video/video_content_type.cc
webrtc += $(pwd)/webrtc/api/video/video_source_interface.cc
webrtc += $(pwd)/webrtc/api/video/video_timing.cc

webrtc += $(pwd)/webrtc/api/video_codecs/sdp_video_format.cc

webrtc += $(pwd)/webrtc/call/call_config.cc
webrtc += $(pwd)/webrtc/call/rtp_demuxer.cc

webrtc += $(pwd)/webrtc/logging/rtc_event_log/events/rtc_event_dtls_transport_state.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/events/rtc_event_dtls_writable_state.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/events/rtc_event_ice_candidate_pair_config.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/events/rtc_event_ice_candidate_pair.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/ice_logger.cc

webrtc += $(filter-out \
    %/adapted_video_track_source.cc \
    %/video_broadcaster.cc \
    %/video_adapter.cc \
    %/video_common.cc \
,$(wildcard $(pwd)/webrtc/media/base/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/media/sctp/*.cc)

webrtc += $(pwd)/webrtc/modules/audio_processing/include/audio_processing_statistics.cc

webrtc += $(wildcard $(pwd)/webrtc/modules/rtp_rtcp/include/*.cc)

webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_dependency_descriptor_extension.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_dependency_descriptor_reader.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_dependency_descriptor_writer.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_generic_frame_descriptor.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_generic_frame_descriptor_extension.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_header_extension_map.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_header_extensions.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_packet.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_packet_received.cc

webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtcp_packet.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtcp_packet/common_header.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtcp_packet/rtpfb.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtcp_packet/transport_feedback.cc

webrtc += $(wildcard $(pwd)/webrtc/modules/utility/source/*.cc)

webrtc += $(wildcard $(pwd)/webrtc/p2p/base/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/p2p/client/*.cc)

webrtc += $(filter-out \
    %/peer_connection_wrapper.cc \
,$(wildcard $(pwd)/webrtc/pc/*.cc))

webrtc += $(filter-out \
    %/gunit.cc \
    %/ifaddrs_converter.cc \
    %/nat_server.cc \
    %/nat_socket_factory.cc \
,$(wildcard $(pwd)/webrtc/rtc_base/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/rtc_base/*/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/rtc_base/*/*.mm)
webrtc += $(wildcard $(pwd)/webrtc/rtc_base/*/*/*.cc)

webrtc += $(wildcard $(pwd)/webrtc/stats/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/system_wrappers/source/*.cc)

cflags/$(pwd)/webrtc/rtc_base/random.cc += -Wno-implicit-int-float-conversion


webrtc += $(wildcard $(pwd)/abseil-cpp/absl/base/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/base/internal/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/types/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/types/internal/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/strings/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/strings/internal/*.cc)
cflags += -I$(pwd)/abseil-cpp


pwd/libsrtp := $(pwd)/libsrtp
webrtc += $(wildcard $(pwd/libsrtp)/srtp/*.c)
cflags += -I$(pwd/libsrtp)/include
webrtc += $(wildcard $(pwd/libsrtp)/crypto/*/*.c)
cflags += -I$(pwd/libsrtp)/crypto/include
libsrtp := -I$(pwd/libsrtp)/config -DHAVE_CONFIG_H -DGCM -DOPENSSL
cflags/$(pwd/libsrtp)/ += $(libsrtp)
cflags/$(pwd/webrtc)/pc/srtp_session.cc += $(libsrtp)

webrtc += $(wildcard $(pwd)/usrsctp/usrsctplib/*.c)
webrtc += $(filter-out %/sctp_cc_functions.c,$(wildcard $(pwd)/usrsctp/usrsctplib/netinet/*.c))
source += $(pwd)/congestion.cc
cflags += -I$(pwd)/usrsctp
cflags += -I$(pwd)/usrsctp/usrsctplib
cflags += -I$(pwd)/sctp-idata/src

ifeq ($(target),win)
cflags/$(pwd)/usrsctp/usrsctplib/ += -Wno-unused-function
cflags/$(pwd)/congestion.cc += -Wno-unused-function
endif


webrtc := $(filter-out %_noop.cc,$(webrtc))

webrtc := $(filter-out %_android.cc,$(webrtc))
webrtc := $(filter-out %_linux.cc,$(webrtc))
webrtc := $(filter-out %_mips.c,$(webrtc))
webrtc := $(filter-out %_mips.cc,$(webrtc))
webrtc := $(filter-out %_neon.c,$(webrtc))
webrtc := $(filter-out %_neon.cc,$(webrtc))

webrtc := $(filter-out $(pwd)/webrtc/rtc_base/strings/json.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/system/%,$(webrtc))
source += $(pwd)/webrtc/rtc_base/system/file_wrapper.cc

webrtc := $(filter-out $(pwd)/webrtc/rtc_base/boringssl_%.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/%_gcd.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/%_libevent.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/mac_%.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/%_stdlib.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/%_win.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/win/%.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/win32%.cc,$(webrtc))

webrtc := $(filter-out %_benchmark.cc,$(webrtc))
webrtc := $(filter-out %_dump.cc,$(webrtc))
webrtc := $(filter-out %_integrationtest.cc,$(webrtc))
webrtc := $(filter-out %_simulations.cc,$(webrtc))
webrtc := $(filter-out %_slowtest.cc,$(webrtc))
webrtc := $(filter-out %_test.cc,$(webrtc))
webrtc := $(filter-out %_test_common.cc,$(webrtc))
webrtc := $(filter-out %_test_helper.cc,$(webrtc))
webrtc := $(filter-out %_testing.cc,$(webrtc))
webrtc := $(filter-out %_tests.cc,$(webrtc))
webrtc := $(filter-out %_unittest.cc,$(webrtc))
webrtc := $(filter-out %_unittest_helper.cc,$(webrtc))
webrtc := $(filter-out %/unittest_main.cc,$(webrtc))


webrtc := $(foreach v,$(webrtc),$(if $(findstring /fake_,$(v)),,$(v)))
webrtc := $(foreach v,$(webrtc),$(if $(findstring /test,$(v)),,$(v)))
webrtc := $(foreach v,$(webrtc),$(if $(findstring /virtual_,$(v)),,$(v)))

source += $(webrtc)


# this is for libwebrtc
cflags += -DHAVE_SCTP

cflags += -DABSL_ALLOCATOR_NOTHROW=0
cflags += -DDCHECK_ALWAYS_ON
cflags += -DWEBRTC_NON_STATIC_TRACE_EVENT_HANDLERS=0

cflags += -DWEBRTC_OPUS_SUPPORT_120MS_PTIME=0

cflags += -DHAVE_STDINT_H
cflags += -DHAVE_STDLIB_H

cflags += -DHAVE_UINT8_T
cflags += -DHAVE_UINT16_T
cflags += -DHAVE_INT32_T
cflags += -DHAVE_UINT32_T
cflags += -DHAVE_UINT64_T

cflags += -DPACKAGE_STRING='""'
# this matches the version of libmaxminddb
cflags += -DPACKAGE_VERSION='"1.5.0"'

cflags += -D__Userspace__
cflags += -DSCTP_DEBUG
cflags += -DSCTP_PROCESS_LEVEL_LOCKS
cflags += -DSCTP_SIMPLE_ALLOCATOR
cflags += -DSCTP_STDINT_INCLUDE='<stdint.h>'
cflags += -DSCTP_USE_OPENSSL_SHA1

include $(pwd)/openssl.mk

include $(pwd)/target-$(target).mk
