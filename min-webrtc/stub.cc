// Orchid - WebRTC P2P VPN Market (on Ethereum)
// Copyright (C) 2017-2020  The Orchid Authors

// Zero Clause BSD license {{{
//
// Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
// }}}


#include "api/video/builtin_video_bitrate_allocator_factory.h"
#include "media/base/video_broadcaster.h"

namespace rtc {
    VideoBroadcaster::VideoBroadcaster() = default;
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

namespace webrtc {
std::unique_ptr<VideoBitrateAllocatorFactory> CreateBuiltinVideoBitrateAllocatorFactory() {
  return nullptr;
} }
