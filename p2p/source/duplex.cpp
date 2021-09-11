/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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


#include "layer.hpp"
#include <boost/beast/core.hpp>
#include <boost/beast/websocket.hpp>

#include "baton.hpp"
#include "duplex.hpp"

namespace orc {

template <typename Handler_>
void async_teardown(boost::beast::role_type role, Adapter &adapter, Handler_ &&handler) {
    orc_insist(false);
}

void beast_close_socket(Adapter &adapter) {
    orc_insist(false);
}

// XXX: this only exists to avoid using auto coroutine below due to clang crash
class Duplex__ :
    public Stream
{
  public:
    virtual task<void> Open(const Locator &locator) = 0;
};

template <typename Inner_>
class Duplex_ final :
    public Duplex__
{
  protected:
    boost::beast::websocket::stream<Inner_> inner_;

  public:
    template <typename ...Args_>
    Duplex_(Args_ &&...args) :
        inner_(std::forward<Args_>(args)...)
    {
        // XXX: this seems important but doesn't support Adapter
        //auto &lowest(boost::beast::get_lowest_layer(inner_));
        //lowest.expires_never();
    }

    decltype(inner_) *operator ->() {
        return &inner_;
    }

    task<void> Open(const Locator &locator) override {
        co_await inner_.async_handshake(locator.origin_.host_, locator.path_, Adapt());
        // XXX: this needs to be configurable :/
        inner_.text(true);
    }

    void Shut() noexcept override {
        Spawn([&]() noexcept -> task<void> { try {
            co_await inner_.async_close(boost::beast::websocket::close_code::normal, Adapt());
        } catch (const asio::system_error &error) {
            orc_except({ orc_adapt(error); })
        } }, __FUNCTION__);
    }

    task<size_t> Read(const Mutables &buffers) override {
        size_t writ;
        try {
            boost::beast::buffers_adaptor buffer(buffers);
            writ = co_await inner_.async_read(buffer, Adapt());
        } catch (const asio::system_error &error) {
            auto code(error.code());
            if (code == asio::error::eof)
                co_return 0;
            orc_adapt(error);
        }

        co_return writ;
    }

    task<void> Send(const Buffer &data) override {
        const size_t writ(co_await [&]() -> task<size_t> { try {
            co_return co_await inner_.async_write(Sequence(data), Adapt());
        } catch (const asio::system_error &error) {
            orc_adapt(error);
        } }());
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
    }
};

task<U<Stream>> Duplex(const S<Base> &base, const Locator &locator) { orc_block({
    co_return co_await Layer<Duplex_>(*base, locator, {}, [&](U<Duplex__> stream) -> task<U<Stream>> {
        co_await stream->Open(locator);
        co_return stream;
    });
}, "opening " << locator); }

}
