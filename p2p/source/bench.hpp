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


#ifndef ORCHID_BENCH_HPP
#define ORCHID_BENCH_HPP

#include <iomanip>

#include <sys/time.h>

#include "log.hpp"

namespace orc {

class Bench {
  private:
    const char *const name_;
    timeval start_;

  public:
    Bench(const char *name) :
        name_(name)
    {
        gettimeofday(&start_, NULL);
    }

    ~Bench() {
        timeval end;
        gettimeofday(&end, NULL);
        timeval diff;
        timersub(&end, &start_, &diff);
        Log() << "Bench(\"" << name_ << "\") = " << diff.tv_sec << "." << std::setfill('0') << std::setw(6) << diff.tv_usec << std::endl;
    }
};

}

#endif//ORCHID_BENCH_HPP
