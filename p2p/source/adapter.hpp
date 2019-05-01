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
#include "trace.hpp"

namespace orc {

template <typename Buffers_>
class Converted final :
    public Buffer
{
  private:
    std::vector<Subset> regions_;
    const Buffers_ &buffers_;

  public:
    Converted(const Buffers_ &buffers) :
        buffers_(buffers)
    {
        for (auto i(buffers_.begin()), e(buffers_.end()); i != e; ++i) {
            const auto &buffer(*i);
            regions_.emplace_back(reinterpret_cast<const uint8_t *>(buffer.data()), buffer.size());
        }
    }

    bool each(const std::function<bool (const Region &)> &code) const override {
        for (const auto &region : regions_)
            if (!code(region))
                return false;
        return true;
    }
};

class Adapter final :
    protected BufferDrain
{
  public:
    typedef Adapter lowest_layer_type;
    typedef boost::asio::io_context::executor_type executor_type;

  private:
    boost::asio::io_context &context_;
    Sink<Link> sink_;

    std::mutex mutex_;
    std::queue<Beam> data_;
    cppcoro::async_auto_reset_event ready_;
    size_t offset_ = 0;

  protected:
    void Land(const Buffer &data) override {
        std::unique_lock<std::mutex> lock(mutex_);
        data_.emplace(data);
        ready_.set();
    }

    void Stop(const std::string &error) override {
        std::unique_lock<std::mutex> lock(mutex_);
        data_.emplace(Nothing());
        ready_.set();
    }

  public:
    Adapter(boost::asio::io_context &context, U<Link> link) :
        context_(context),
        sink_(this, std::move(link))
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
        Task([this, buffers, handler = std::move(handler)]() mutable -> task<void> {
            for (;; co_await ready_, co_await Schedule()) {
                std::unique_lock<std::mutex> lock(mutex_);
                if (!data_.empty()) {
                    const auto &beam(data_.front());
                    // XXX: handle errors
                    auto base(beam.data());
                    auto rest(beam.size() - offset_);
                    auto writ(0);

                    const auto &buffer(buffers); do {
                    //for (const auto &buffer : buffers) {
                        if (rest == 0)
                            break;

                        auto copy(std::min(buffer.size(), rest));
                        memcpy(buffer.data(), base + offset_, copy);

                        // XXX: too many variables
                        rest -= copy;
                        offset_ += copy;
                        writ += copy;
                    //}
                    } while (false);

                    if (rest == 0) {
                        data_.pop();
                        offset_ = 0;
                    }

                    boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::system::error_code(), writ));
                    break;
                }
            }
        });
    }

    template <typename Buffers_, typename Handler_>
    void async_write_some(const Buffers_ &buffers, Handler_ handler) {
        Task([this, buffers, handler = std::move(handler)]() mutable -> task<void> {
            Converted converted(buffers);
            co_await sink_->Send(converted);
            boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::system::error_code(), converted.size()));
        });
    }
};

}

#endif//ORCHID_ADAPTER_HPP
