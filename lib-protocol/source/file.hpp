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


#ifndef ORCHID_FILE_HPP
#define ORCHID_FILE_HPP

#include <asio/ip/tcp.hpp>
#include <asio/ip/udp.hpp>

#include "baton.hpp"
#include "category.hpp"
#include "link.hpp"
#include "reader.hpp"
#include "task.hpp"

namespace orc {

template <typename File_>
class File final :
    public Stream
{
  private:
    File_ file_;

  public:
    template <typename... Args_>
    File(Args_ &&...args) :
        file_(std::forward<Args_>(args)...)
    {
    }

    File_ &operator *() {
        return file_;
    }

    File_ *operator ->() {
        return &file_;
    }

    task<size_t> Read(const Mutables &buffers) override {
        size_t writ;
        try {
            writ = co_await file_.async_read_some(buffers, Adapt());
        } catch (const asio::system_error &error) {
            const auto code(error.code());
            if (code == asio::error::eof)
                co_return 0;
            orc_adapt(error);
        }

        co_return writ;
    }

    void Shut() noexcept override {
        file_.close();
    }

    task<void> Send(const Buffer &data) override {
        const auto writ(co_await file_.async_write_some(Window(data), Adapt()));
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
    }
};

}

#endif//ORCHID_FILE_HPP
