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

#include "link.hpp"
#include "trace.hpp"

namespace orc {

// XXX: this is wrong, as the Subsets are temporary :/
template <typename Buffers_>
class Wrapper :
    public Buffer
{
  private:
    const Buffers_ &buffers_;

  public:
    Wrapper(const Buffers_ &buffers) :
        buffers_(buffers)
    {
    }

    void each(const std::function<void (const Region &)> &code) const override {
        for (auto i(buffers_.begin()), e(buffers_.end()); i != e; ++i) {
            const auto &buffer(*i);
            code(Subset(static_cast<const uint8_t *>(buffer.data()), buffer.size()));
        }
    }
};

class Adapter {
  public:
    typedef Adapter lowest_layer_type;
    typedef boost::asio::io_context::executor_type executor_type;

  private:
    boost::asio::io_context &context_;
    U<Link> link_;

  public:
    Adapter(boost::asio::io_context &context, U<Link> link) :
        context_(context),
        link_(std::move(link))
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
        boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::system::error_code(), 31337));
    }

    template <typename Buffers_, typename Handler_>
    void async_write_some(const Buffers_ &buffers, Handler_ handler) {
        Wrapper<Buffers_> wrapper(buffers);
        Wait(link_->Send(wrapper));
        boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::system::error_code(), 31337));
    }
};

}

#endif//ORCHID_ADAPTER_HPP
