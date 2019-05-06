# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pwd := ./$(patsubst %/,%,$(patsubst $(CURDIR)/%,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST))))))

webrtc := 

c_webrtc += -Wundef

cflags += -I$(pwd)/extra


webrtc += $(filter-out %/create_peerconnection_factory.cc,$(wildcard $(pwd)/webrtc/api/*.cc))
webrtc += $(wildcard $(pwd)/webrtc/api/crypto/*.cc)
webrtc += $(filter-out %/goog_cc_factory.cc,$(wildcard $(pwd)/webrtc/api/transport/*.cc))
webrtc += $(wildcard $(pwd)/webrtc/api/units/*.cc)

webrtc += $(pwd)/webrtc/api/audio_codecs/audio_encoder.cc
webrtc += $(pwd)/webrtc/api/audio_codecs/audio_format.cc

webrtc += $(pwd)/webrtc/api/task_queue/task_queue_base.cc

source += $(pwd)/webrtc/api/video/color_space.cc
webrtc += $(pwd)/webrtc/api/video/encoded_image.cc
webrtc += $(pwd)/webrtc/api/video/hdr_metadata.cc
webrtc += $(pwd)/webrtc/api/video/video_content_type.cc
webrtc += $(pwd)/webrtc/api/video/video_source_interface.cc
webrtc += $(pwd)/webrtc/api/video/video_timing.cc

webrtc += $(pwd)/webrtc/call/call_config.cc 
webrtc += $(pwd)/webrtc/call/rtp_demuxer.cc

webrtc += $(pwd)/webrtc/logging/rtc_event_log/events/rtc_event_dtls_transport_state.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/events/rtc_event_dtls_writable_state.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/events/rtc_event_ice_candidate_pair_config.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/events/rtc_event_ice_candidate_pair.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/output/rtc_event_log_output_file.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/ice_logger.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/rtc_event_log.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/rtc_event_log_impl.cc

webrtc += $(pwd)/webrtc/media/base/codec.cc
webrtc += $(pwd)/webrtc/media/base/h264_profile_level_id.cc
webrtc += $(pwd)/webrtc/media/base/media_channel.cc
webrtc += $(pwd)/webrtc/media/base/media_constants.cc
webrtc += $(pwd)/webrtc/media/base/media_engine.cc
webrtc += $(pwd)/webrtc/media/base/rid_description.cc
webrtc += $(pwd)/webrtc/media/base/rtp_data_engine.cc
webrtc += $(pwd)/webrtc/media/base/rtp_utils.cc
webrtc += $(pwd)/webrtc/media/base/stream_params.cc
webrtc += $(pwd)/webrtc/media/base/turn_utils.cc
webrtc += $(pwd)/webrtc/media/base/video_source_base.cc
webrtc += $(pwd)/webrtc/media/base/vp9_profile.cc

webrtc += $(wildcard $(pwd)/webrtc/media/sctp/*.cc)

webrtc += $(pwd)/webrtc/modules/audio_processing/include/audio_processing_statistics.cc
webrtc += $(wildcard $(pwd)/webrtc/modules/congestion_controller/bbr/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/modules/include/*.cc)

webrtc += $(pwd)/webrtc/modules/rtp_rtcp/include/rtp_rtcp_defines.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_generic_frame_descriptor.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_generic_frame_descriptor_extension.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_header_extension_map.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_header_extensions.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_packet.cc
webrtc += $(pwd)/webrtc/modules/rtp_rtcp/source/rtp_packet_received.cc

webrtc += $(wildcard $(pwd)/webrtc/modules/utility/source/*.cc)

webrtc += $(filter-out \
    %/udptransport.cc \
,$(wildcard $(pwd)/webrtc/p2p/base/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/p2p/client/*.cc)

webrtc += $(filter-out \
    %/bundlefilter.cc \
    %/peer_connection_wrapper.cc \
,$(wildcard $(pwd)/webrtc/pc/*.cc))

webrtc += $(filter-out \
    %/ifaddrs_converter.cc \
    %/gunit.cc \
,$(wildcard $(pwd)/webrtc/rtc_base/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/rtc_base/*/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/rtc_base/*/*.mm)
webrtc += $(wildcard $(pwd)/webrtc/rtc_base/*/*/*.cc)

webrtc += $(wildcard $(pwd)/webrtc/stats/*.cc)

webrtc += $(wildcard $(pwd)/webrtc/system_wrappers/source/*.cc)


webrtc += $(wildcard $(pwd)/abseil-cpp/absl/base/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/base/internal/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/types/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/types/internal/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/strings/*.cc)
webrtc += $(wildcard $(pwd)/abseil-cpp/absl/strings/internal/*.cc)
cflags += -I$(pwd)/abseil-cpp

webrtc += $(wildcard $(pwd)/boringssl/crypto/*.c)
webrtc += $(wildcard $(pwd)/boringssl/crypto/*/*.c)
webrtc += $(wildcard $(pwd)/boringssl/ssl/*.cc)
webrtc += $(wildcard $(pwd)/boringssl/third_party/fiat/curve25519.c)

source += $(output)/err_data.c
$(output)/err_data.c: $(pwd)/boringssl/crypto/err/err_data_generate.go
	@mkdir -p $(dir $@)
	(cd $(dir $<); go run $(notdir $<)) >$@

webrtc += $(wildcard $(pwd)/third_party/boringssl/err_data.c)

webrtc += $(wildcard $(pwd)/jsoncpp/src/lib_json/*.cpp)
cflags += -I$(pwd)/jsoncpp/include

webrtc += $(wildcard $(pwd)/libsrtp/srtp/*.c)
cflags += -I$(pwd)/libsrtp/include
webrtc += $(wildcard $(pwd)/libsrtp/crypto/*/*.c)
cflags += -I$(pwd)/libsrtp/crypto/include

webrtc += $(wildcard $(pwd)/usrsctp/usrsctplib/*.c)
webrtc += $(wildcard $(pwd)/usrsctp/usrsctplib/netinet/*.c)
cflags += -I$(pwd)/usrsctp
cflags += -I$(pwd)/usrsctp/usrsctplib
cflags += -I$(pwd)/sctp-idata/src


webrtc := $(filter-out %_noop.cc,$(webrtc))

webrtc := $(filter-out %_android.cc,$(webrtc))
webrtc := $(filter-out %_mips.c,$(webrtc))
webrtc := $(filter-out %_mips.cc,$(webrtc))
webrtc := $(filter-out %_neon.c,$(webrtc))
webrtc := $(filter-out %_neon.cc,$(webrtc))

webrtc := $(filter-out $(pwd)/webrtc/rtc_base/system/%,$(webrtc))

webrtc := $(filter-out $(pwd)/webrtc/rtc_base/mac_%.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/%_libevent.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/%_gcd.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/%_win.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/win32%.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/win/%.cc,$(webrtc))

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

webrtc := $(foreach v,$(webrtc),$(if $(findstring /test,$(v)),,$(v)))


cflags += -I$(pwd)/webrtc

source += $(webrtc)
source += $(pwd)/stub.cc

cflags += -DOPENSSL

cflags += -DSCTP_SIMPLE_ALLOCATOR
cflags += -D__FreeBSD_version=0

cflags += -DABSL_ALLOCATOR_NOTHROW=0
cflags += -DWEBRTC_NON_STATIC_TRACE_EVENT_HANDLERS=0

cflags += -DWEBRTC_OPUS_SUPPORT_120MS_PTIME=0

cflags += -DHAVE_SCTP

cflags += -DOPENSSL_NO_ASM

cflags += -DHAVE_STDINT_H
cflags += -DHAVE_STDLIB_H

cflags += -DHAVE_CONFIG_H

cflags += -DHAVE_UINT8_T
cflags += -DHAVE_UINT16_T
cflags += -DHAVE_INT32_T
cflags += -DHAVE_UINT32_T
cflags += -DHAVE_UINT64_T

cflags += -DPACKAGE_STRING='""'
cflags += -DPACKAGE_VERSION='""'

cflags += -Wno-deprecated-declarations
cflags += -Wno-inconsistent-missing-override
cflags += -Wno-unused-function

cflags += -D__Userspace__
cflags += -DSCTP_USE_OPENSSL_SHA1
cflags += -DSCTP_SIMPLE_ALLOCATOR
cflags += -DSCTP_PROCESS_LEVEL_LOCKS


include $(pwd)/libevent.mk
include $(pwd)/target-$(target).mk
