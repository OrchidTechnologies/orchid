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


#ifndef ORCHID_LOG_HPP
#define ORCHID_LOG_HPP

#include <cstdarg>
#include <sstream>

namespace orc {

extern bool Verbose;

class Fiber;

class Log final :
    public std::ostringstream
{
  public:
    Log(Fiber *fiber = nullptr) noexcept;
    ~Log() override;
};

std::string Cause();

}

inline constexpr orc::Fiber *const orc_fiber = nullptr;

#define orc_head \
    [[maybe_unused]] Fiber *const orc_fiber(nullptr);
#define orc_ahead \
    [[maybe_unused]] Fiber *const orc_fiber(co_await orc_optic);

#define orc_Log() \
    orc::Log(orc_fiber)

#define orc_log(log, text) \
    log << "[" << __FILE__ << ":" << std::dec << __LINE__ << "] " << text

#define orc_trace() do { \
    orc_log(orc_Log() << "\e[31m", "orc_trace(): " << __FUNCTION__ << std::endl); \
} while (false)

#endif//ORCHID_LOG_HPP
