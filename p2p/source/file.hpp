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

    File_ *operator ->() {
        return &file_;
    }

    task<size_t> Read(Beam &beam) override {
	size_t writ;
	try {
	    writ = co_await file_.async_read_some(asio::buffer(beam.data(), beam.size()), Token());
	} catch (const asio::system_error &error) {
	    const auto code(error.code());
	    if (code == asio::error::eof)
                co_return 0;
            orc_adapt(error);
	}

        if (Verbose)
            Log() << "\e[33mRECV " << writ << " " << beam.subset(0, writ) << "\e[0m" << std::endl;
        co_return writ;
    }

    task<void> Shut() override {
        file_.close();
        co_return;
    }

    task<void> Send(const Buffer &data) override {
        if (Verbose)
            Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;

        const auto writ(co_await file_.async_write_some(Sequence(data), Token()));
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
    }
};

}

#endif//ORCHID_FILE_HPP
