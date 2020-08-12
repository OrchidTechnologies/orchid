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


#include <thread>

#include <boost/asio/executor_work_guard.hpp>

#include "baton.hpp"
#include "memory.hpp"

namespace orc {

asio::io_context &Context() {
    static asio::io_context context;
    static auto work(asio::make_work_guard(context));
    Thread();
    return context;
}

std::thread &Thread() {
    static std::thread thread([]() {
        Context().run();
    });
    return thread;
}

// XXX: make the server (at least) exit safely on control-C
// asio::signal_set signals(Context(), SIGINT, SIGTERM);
// signals.async_wait([&](auto, auto) { orc_trace(); Context().stop(); });

}
