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


#ifndef ORCHID_LOG_HPP
#define ORCHID_LOG_HPP

#include <cstdarg>
#include <sstream>

#include <pthread.h>

namespace orc {

extern bool Verbose;

class Log final :
    public std::ostringstream
{
  public:
    ~Log() override;
};

}

#define orc_log(log, text) \
    log << "[" << __FILE__ << ":" << std::dec << __LINE__ << "] [" << pthread_self() << "] " << text

#define orc_trace() do { \
    orc_log(orc::Log() << "\e[31m", " orc_trace(): " << __FUNCTION__ << "\e[0m" << std::endl); \
} while (false)

#endif//ORCHID_LOG_HPP
