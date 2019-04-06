// Orchid - WebRTC P2P VPN Market (on Ethereum)
// Copyright (C) 2017-2019  The Orchid Authors

// Zero Clause BSD license {{{
//
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// }}}


#include <media/base/videobroadcaster.h>
#include <media/engine/webrtcmediaengine.h>

#include <call/callfactory.h>

#include <pc/videocapturertracksource.h>

namespace rtc {
    VideoBroadcaster::VideoBroadcaster() {
        thread_checker_.DetachFromThread();
    }

    VideoBroadcaster::~VideoBroadcaster() = default;

    void VideoBroadcaster::AddOrUpdateSink(VideoSinkInterface<webrtc::VideoFrame> *sink, const VideoSinkWants &wants) {
    }

    void VideoBroadcaster::RemoveSink(VideoSinkInterface<webrtc::VideoFrame> *sink) {
    }

    void VideoBroadcaster::OnFrame(const webrtc::VideoFrame &frame) {
    }

    void VideoBroadcaster::OnDiscardedFrame() {
    }
}

namespace cricket {
std::unique_ptr<MediaEngineInterface> WebRtcMediaEngineFactory::Create(
    rtc::scoped_refptr<webrtc::AudioDeviceModule> adm,
    rtc::scoped_refptr<webrtc::AudioEncoderFactory> audio_encoder_factory,
    rtc::scoped_refptr<webrtc::AudioDecoderFactory> audio_decoder_factory,
    std::unique_ptr<webrtc::VideoEncoderFactory> video_encoder_factory,
    std::unique_ptr<webrtc::VideoDecoderFactory> video_decoder_factory,
    rtc::scoped_refptr<webrtc::AudioMixer> audio_mixer,
    rtc::scoped_refptr<webrtc::AudioProcessing> audio_processing
) {
    return nullptr;
} }

namespace webrtc {
std::unique_ptr<CallFactoryInterface> CreateCallFactory() {
    return nullptr;
} }

namespace webrtc {
    AudioProcessingBuilder::AudioProcessingBuilder() = default;
    AudioProcessingBuilder::~AudioProcessingBuilder() = default;

    AudioProcessing *AudioProcessingBuilder::Create() {
        return nullptr;
    }
}

namespace webrtc {
rtc::scoped_refptr<VideoTrackSourceInterface> VideoCapturerTrackSource::Create(
    rtc::Thread* worker_thread,
    std::unique_ptr<cricket::VideoCapturer> capturer,
    const webrtc::MediaConstraintsInterface* constraints,
    bool remote
) {
    return nullptr;
} }

namespace webrtc {
rtc::scoped_refptr<VideoTrackSourceInterface> VideoCapturerTrackSource::Create(
    rtc::Thread* worker_thread,
    std::unique_ptr<cricket::VideoCapturer> capturer,
    bool remote
) {
    return nullptr;
} }
