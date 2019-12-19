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

#include <queue>

#include <cppcoro/async_auto_reset_event.hpp>

#include "link.hpp"
#include "locked.hpp"
#include "trace.hpp"

namespace orc {

template <typename Buffers_>
class Converted final :
    public Buffer
{
  private:
    const std::vector<Range> ranges_;

  public:
    Converted(const Buffers_ &buffers) :
        ranges_([&]() {
            std::vector<Range> ranges;
            ranges.reserve(buffers.size());
            for (const auto &buffer : buffers)
                ranges.emplace_back(reinterpret_cast<const uint8_t *>(buffer.data()), buffer.size());
            return ranges;
        })
    {
    }

    bool each(const std::function<bool (const uint8_t *, size_t)> &code) const noexcept override {
        for (const auto &range : ranges_)
            if (!code(range.data(), range.size()))
                return false;
        return true;
    }
};

// XXX: we need to map the error codes in this file to something better

class Adapter :
    public BufferDrain
{
  public:
    typedef Adapter lowest_layer_type;
    typedef boost::asio::io_context::executor_type executor_type;

  private:
    boost::asio::io_context &context_;

    struct Locked_ {
        std::queue<Beam> data_;
        size_t offset_ = 0;
    }; Locked<Locked_> locked_;

    cppcoro::async_auto_reset_event ready_;

  protected:
    virtual Pump<Buffer> *Inner() = 0;

    void Land(const Buffer &data) override {
        locked_()->data_.emplace(data);
        ready_.set();
    }

    void Stop(const std::string &error) noexcept override {
        // XXX: locked_()->data_.emplace(Beam());
        ready_.set();
    }

  public:
    Adapter(boost::asio::io_context &context) :
        context_(context)
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
            for (;; co_await ready_, co_await Schedule()) {
                const auto locked(locked_());
                if (!locked->data_.empty()) {
                    const auto &beam(locked->data_.front());
                    // XXX: handle errors
                    const auto base(beam.data());
                    auto rest(beam.size() - locked->offset_);
                    auto writ(0);

                    const auto &buffer(buffers); do {
                    //for (const auto &buffer : buffers) {
                        if (rest == 0)
                            break;

                        auto copy(std::min(buffer.size(), rest));
                        memcpy(buffer.data(), base + locked->offset_, copy);

                        // XXX: too many variables
                        rest -= copy;
                        locked->offset_ += copy;
                        writ += copy;
                    //}
                    } while (false);

                    if (rest == 0) {
                        locked->data_.pop();
                        locked->offset_ = 0;
                    }

                    boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::system::error_code(), writ));
                    break;
                }
            }
        });
    }

    template <typename Buffers_, typename Handler_>
    void async_write_some(const Buffers_ &buffers, Handler_ handler) {
        Spawn([this, buffers, handler = std::move(handler)]() mutable noexcept -> task<void> {
            try {
                const Converted converted(buffers);
                co_await Inner()->Send(converted);
                boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::system::error_code(), converted.size()));
            } catch (...) {
                boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::asio::error::invalid_argument, 0));
            }
        });
    }
};

}

#endif//ORCHID_ADAPTER_HPP
