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


# XXX: wrapping_async_dns_resolver.cc should have been deleted in 24510d43dccc88a47e2cd139b2190e25d4c7b700
webrtc += $(filter-out \
    %/create_peerconnection_factory.cc \
    %/enable_media.cc \
    %/enable_media_with_defaults.cc \
    %/field_trials_registry.cc \
    %/frame_transformer_factory.cc \
    %/wrapping_async_dns_resolver.cc \
,$(wildcard $(pwd)/webrtc/api/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/api/crypto/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/api/task_queue/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/api/transport/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/api/transport/media/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/api/transport/rtp/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/api/units/*.cc)

webrtc += $(pwd)/webrtc/api/field_trials_registry.cc

webrtc += $(pwd)/webrtc/api/audio/audio_processing_statistics.cc

webrtc += $(pwd)/webrtc/api/audio_codecs/audio_codec_pair_id.cc
webrtc += $(pwd)/webrtc/api/audio_codecs/audio_encoder.cc
webrtc += $(pwd)/webrtc/api/audio_codecs/audio_format.cc

webrtc += $(pwd)/webrtc/api/call/transport.cc
webrtc += $(pwd)/webrtc/api/environment/environment_factory.cc
webrtc += $(pwd)/webrtc/api/numerics/samples_stats_counter.cc

webrtc += $(pwd)/webrtc/api/rtc_event_log/rtc_event.cc
webrtc += $(pwd)/webrtc/api/rtc_event_log/rtc_event_log.cc

webrtc += $(pwd)/webrtc/api/video/color_space.cc
webrtc += $(pwd)/webrtc/api/video/encoded_frame.cc
webrtc += $(pwd)/webrtc/api/video/encoded_image.cc
webrtc += $(pwd)/webrtc/api/video/hdr_metadata.cc
webrtc += $(pwd)/webrtc/api/video/video_bitrate_allocation.cc
webrtc += $(pwd)/webrtc/api/video/video_content_type.cc
webrtc += $(pwd)/webrtc/api/video/video_frame_metadata.cc
webrtc += $(pwd)/webrtc/api/video/video_source_interface.cc
webrtc += $(pwd)/webrtc/api/video/video_timing.cc

webrtc += $(pwd)/webrtc/api/video_codecs/av1_profile.cc
webrtc += $(pwd)/webrtc/api/video_codecs/h264_profile_level_id.cc
webrtc += $(pwd)/webrtc/api/video_codecs/scalability_mode.cc
webrtc += $(pwd)/webrtc/api/video_codecs/sdp_video_format.cc
webrtc += $(pwd)/webrtc/api/video_codecs/simulcast_stream.cc
webrtc += $(pwd)/webrtc/api/video_codecs/video_codec.cc
webrtc += $(pwd)/webrtc/api/video_codecs/vp9_profile.cc

webrtc += $(pwd)/webrtc/call/call_config.cc
webrtc += $(pwd)/webrtc/call/payload_type_picker.cc
webrtc += $(pwd)/webrtc/call/rtp_bitrate_configurator.cc
webrtc += $(pwd)/webrtc/call/rtp_config.cc
webrtc += $(pwd)/webrtc/call/rtp_demuxer.cc
webrtc += $(pwd)/webrtc/call/rtp_payload_params.cc
webrtc += $(pwd)/webrtc/call/rtp_transport_controller_send.cc
webrtc += $(pwd)/webrtc/call/rtp_video_sender.cc

webrtc += $(pwd)/webrtc/common_video/corruption_detection_converters.cc

webrtc += $(pwd)/webrtc/common_video/generic_frame_descriptor/generic_frame_info.cc

webrtc += $(pwd)/webrtc/common_video/h264/h264_common.cc
webrtc += $(pwd)/webrtc/common_video/h264/pps_parser.cc
webrtc += $(pwd)/webrtc/common_video/h264/sps_parser.cc
webrtc += $(pwd)/webrtc/common_video/h264/sps_vui_rewriter.cc

webrtc += $(pwd)/webrtc/logging/rtc_event_log/encoder/bit_writer.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/encoder/var_int.cc

webrtc += $(pwd)/webrtc/logging/rtc_event_log/ice_logger.cc
webrtc += $(pwd)/webrtc/logging/rtc_event_log/rtc_stream_config.cc

webrtc += $(wildcard $(pwd)/webrtc/logging/rtc_event_log/events/*.cc)

webrtc += $(filter-out \
    %/adapted_video_track_source.cc \
    %/video_broadcaster.cc \
    %/video_adapter.cc \
    %/video_common.cc \
,$(wildcard $(pwd)/webrtc/media/base/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/media/sctp/*.cc)

webrtc += $(pwd)/webrtc/modules/audio_coding/audio_network_adaptor/audio_network_adaptor_config.cc

webrtc += $(wildcard $(pwd)/webrtc/modules/congestion_controller/goog_cc/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/modules/congestion_controller/rtp/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/modules/pacing/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/modules/remote_bitrate_estimator/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/modules/rtp_rtcp/include/*.cc)

webrtc += $(filter-out \
    %_h265.cc \
,$(wildcard $(pwd)/webrtc/modules/rtp_rtcp/source/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/modules/rtp_rtcp/source/deprecated/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/modules/rtp_rtcp/source/rtcp_packet/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/modules/utility/source/*.cc)

webrtc += $(pwd)/webrtc/modules/video_coding/chain_diff_calculator.cc
webrtc += $(pwd)/webrtc/modules/video_coding/encoded_frame.cc
webrtc += $(pwd)/webrtc/modules/video_coding/frame_dependencies_calculator.cc
# XXX: why is this in the include folder?!
webrtc += $(pwd)/webrtc/modules/video_coding/include/video_codec_interface.cc

webrtc += $(filter-out \
    %/reassembly_streams.cc \
,$(shell find $(pwd)/webrtc/net -name '*.cc' | LC_COLLATE=C sort))

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
    %/trace_categories.cc \
,$(wildcard $(pwd)/webrtc/rtc_base/*.cc))

# XXX: I'd prefer to remove all %/experiments/*
webrtc += $(filter-out \
    %/experiments/encoder_info_settings.cc \
,$(wildcard $(pwd)/webrtc/rtc_base/*/*.cc))

webrtc += $(wildcard $(pwd)/webrtc/rtc_base/*/*.mm)
webrtc += $(wildcard $(pwd)/webrtc/rtc_base/*/*/*.cc)

webrtc += $(wildcard $(pwd)/webrtc/stats/*.cc)
webrtc += $(wildcard $(pwd)/webrtc/system_wrappers/source/*.cc)


pwd/libsrtp := $(pwd)/libsrtp
webrtc += $(wildcard $(pwd/libsrtp)/srtp/*.c)
cflags += -I$(pwd/libsrtp)/include
webrtc += $(wildcard $(pwd/libsrtp)/crypto/*/*.c)
cflags += -I$(pwd/libsrtp)/crypto/include
libsrtp := -I$(pwd/libsrtp)/config -DHAVE_CONFIG_H -DGCM -DOPENSSL
cflags/$(pwd/libsrtp)/ += $(libsrtp)
cflags/$(pwd/webrtc)/pc/srtp_session.cc += $(libsrtp)
cflags/$(pwd/webrtc)/pc/external_hmac.cc += -I$(pwd/libsrtp)/config

webrtc += $(wildcard $(pwd)/crc32c/src/*.cc)


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
webrtc := $(filter-out $(pwd)/webrtc/%_gcd.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/%_libevent.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/%_libevent_experiment.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/rtc_base/mac_%.cc,$(webrtc))
webrtc := $(filter-out $(pwd)/webrtc/%_win.cc,$(webrtc))
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
webrtc := $(filter-out %_test_main.cc,$(webrtc))
webrtc := $(filter-out %_testing.cc,$(webrtc))
webrtc := $(filter-out %_tests.cc,$(webrtc))
webrtc := $(filter-out %_unittest.cc,$(webrtc))
webrtc := $(filter-out %_unittest_helper.cc,$(webrtc))
webrtc := $(filter-out %/unittest_main.cc,$(webrtc))


webrtc := $(foreach v,$(webrtc),$(if $(findstring /fake_,$(v)),,$(v)))
webrtc := $(foreach v,$(webrtc),$(if $(findstring /test,$(v)),,$(v)))
webrtc := $(foreach v,$(webrtc),$(if $(findstring /virtual_,$(v)),,$(v)))

source += $(webrtc)


$(output)/$(pwd/webrtc)/experiments/registered_field_trials.h: $(pwd/webrtc)/experiments/field_trials.py
	@mkdir -p $(dir $@)
	python3 $< header >$@
header += $(output)/$(pwd/webrtc)/experiments/registered_field_trials.h
cflags += -I$(output)/$(pwd/webrtc)


cflags += -DWEBRTC_HAVE_SCTP
cflags += -DWEBRTC_HAVE_DCSCTP

cflags += -DABSL_ALLOCATOR_NOTHROW=0
#cflags += -DDCHECK_ALWAYS_ON
cflags += -DWEBRTC_NON_STATIC_TRACE_EVENT_HANDLERS=0

cflags += -DWEBRTC_OPUS_SUPPORT_120MS_PTIME=0

cflags += -DHAVE_STDINT_H
cflags += -DHAVE_STDLIB_H

cflags += -DHAVE_UINT8_T
cflags += -DHAVE_UINT16_T
cflags += -DHAVE_INT32_T
cflags += -DHAVE_UINT32_T
cflags += -DHAVE_UINT64_T

cflags/$(pwd)/libsrtp/ += -DPACKAGE_STRING='""'
cflags/$(pwd)/libsrtp/ += -DPACKAGE_VERSION='""'

cflags += -D__Userspace__
cflags += -DSCTP_DEBUG
cflags += -DSCTP_PROCESS_LEVEL_LOCKS
cflags += -DSCTP_SIMPLE_ALLOCATOR
cflags += -DSCTP_STDINT_INCLUDE='<stdint.h>'
cflags += -DSCTP_USE_OPENSSL_SHA1

# disable dcsctp congestion controller
chacks/$(pwd/webrtc)/media/sctp/dcsctp_transport.cc += s/ options;/ options{.cwnd_mtus_initial = 10000, .cwnd_mtus_min = 10000};/g;
# do not allocate statistics collector
chacks/$(pwd/webrtc)/pc/rtc_stats_collector.cc += s/rtc::make_ref_counted<RTCStatsCollector>([^;]*/nullptr/g;
# completely prevent the use of FD_SET
chacks/$(pwd/webrtc)/rtc_base/physical_socket_server.cc += /::WaitSelect/s/$$/ return false;/;

# XXX: https://bugs.chromium.org/p/webrtc/issues/detail?id=12967
chacks/$(pwd/webrtc)/p2p/base/dtls_transport.cc += /Should not happen\./,/;/d;

# XXX: https://issues.webrtc.org/issues/339131894
chacks/$(pwd/webrtc)/p2p/base/stun_port.cc += /^void UDPPort::OnResolveResult(/,/^}/s/^}/MaybeSetPortCompleteOrError();}/

# XXX: just chacks/ this fwrite to somehow access orc::Log
# XXX: a bug needs to be filed for this :/
# vpn/p2p/rtc/webrtc/rtc_base/checks.cc:49:3: error: ignoring return value of function declared with 'warn_unused_result' attribute [-Werror,-Wunused-result]
#   fwrite(output.data(), output.size(), 1, stderr);
#   ^~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cflags/$(pwd/webrtc)/rtc_base/checks.cc += -Wno-unused-result


include $(pwd)/target-$(target).mk
