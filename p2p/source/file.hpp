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


#ifndef ORCHID_FILE_HPP
#define ORCHID_FILE_HPP

#include <asio/ip/tcp.hpp>
#include <asio/ip/udp.hpp>

#include <cppcoro/async_manual_reset_event.hpp>
#include <cppcoro/async_mutex.hpp>

#include "baton.hpp"
#include "link.hpp"
#include "task.hpp"

namespace orc {

template <typename File_>
class File final :
    public Link
{
  private:
    File_ file_;
    cppcoro::async_mutex send_;

  public:
    template <typename... Args_>
    File(BufferDrain *drain, Args_ &&...args) :
        Link(drain),
        file_(Context(), std::forward<Args_>(args)...)
    {
    }

    File_ *operator ->() {
        return &file_;
    }

    void Start() {
        Spawn([this]() -> task<void> {
            for (;;) {
                char data[2048];
                size_t writ;
                try {
                    writ = co_await file_.async_read_some(asio::buffer(data), Token());
                } catch (const asio::error_code &error) {
                    if (error == asio::error::eof)
                        Link::Stop();
                    else {
                        auto message(error.message());
                        orc_assert(!message.empty());
                        Link::Stop(message);
                    }
                    break;
                }

                Subset region(data, writ);
                if (Verbose)
                    Log() << "\e[33mRECV " << writ << " " << region << "\e[0m" << std::endl;
                Land(region);
            }
        });
    }

    ~File() override {
_trace();
    }

    task<void> Send(const Buffer &data) override {
        if (Verbose)
            Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;

        if (!data.empty()) {
            auto lock(co_await send_.scoped_lock_async());
            auto writ(co_await file_.async_write_some(Sequence(data), Token()));
            orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
        }
    }

    task<void> Shut() override {
        file_.close();
        co_await Link::Shut();
    }
};

}

#endif//ORCHID_FILE_HPP
