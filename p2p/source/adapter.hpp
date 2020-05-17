/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2019  The Orchid Authors
*/

/* GNU Affero General Public License, Version 3 {{{ */
/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */


#ifndef ORCHID_ADAPTER_HPP
#define ORCHID_ADAPTER_HPP

#include <boost/beast/core/buffers_range.hpp>

#include "reader.hpp"

namespace orc {

template <typename Buffers_>
class Converted final :
    public Buffer
{
  private:
    const Buffers_ &buffers_;

  public:
    Converted(const Buffers_ &buffers) :
        buffers_(buffers)
    {
    }

    bool each(const std::function<bool (const uint8_t *, size_t)> &code) const noexcept override {
        for (const auto &range : boost::beast::buffers_range_ref(buffers_))
            if (!code(static_cast<const uint8_t *>(range.data()), range.size()))
                return false;
        return true;
    }
};

class Adapter {
  public:
    typedef Adapter lowest_layer_type;
    typedef boost::asio::io_context::executor_type executor_type;

  private:
    boost::asio::io_context &context_;
    U<Stream> stream_;

  public:
    Adapter(boost::asio::io_context &context, U<Stream> stream) :
        context_(context),
        stream_(std::move(stream))
    {
    }

    Adapter &lowest_layer() {
        return *this;
    }

    executor_type get_executor() {
        return context_.get_executor();
    }

    template <typename Buffers_, typename Handler_>
    void async_read_some(const Buffers_ &buffers, Handler_ handler) {
        Spawn([this, buffers, handler = std::move(handler)]() mutable noexcept -> task<void> {
            try {
                typedef std::pair<size_t, boost::system::error_code> Result;
                const auto [writ, error] = co_await [&]() -> task<Result> {
                    const auto size(boost::beast::buffer_bytes(buffers));
                    if (size == 0)
                        co_return Result(0, {});

                    Beam beam(size);
                    const auto writ(co_await stream_->Read(beam));
                    if (writ == 0)
                        co_return Result(0, asio::error::eof);

                    auto data(beam.data());
                    // XXX: this is copying way too much data
                    for (const auto &range : boost::beast::buffers_range_ref(buffers)) {
                        const auto size(range.size());
                        Copy(range.data(), data, size);
                        data += size;
                    }

                    co_return Result(writ, {});
                }();

                boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), error, writ));
            } catch (...) {
                // XXX: convert Error
                boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::asio::error::invalid_argument, 0));
            }
        });
    }

    void shutdown(boost::asio::socket_base::shutdown_type type) noexcept {
        if (type != boost::asio::socket_base::shutdown_receive)
            stream_->Shut();
    }

    template <typename Buffers_, typename Handler_>
    void async_write_some(const Buffers_ &buffers, Handler_ handler) {
        Spawn([this, buffers, handler = std::move(handler)]() mutable noexcept -> task<void> {
            try {
                const Converted data(buffers);
                co_await stream_->Send(data);
                boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::system::error_code(), data.size()));
            } catch (...) {
                // XXX: convert Error
                boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::asio::error::invalid_argument, 0));
            }
        });
    }
};

}

#endif//ORCHID_ADAPTER_HPP
