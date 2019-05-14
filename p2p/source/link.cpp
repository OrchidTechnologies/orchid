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


#include <iomanip>

#include <unistd.h>

#include "link.hpp"
#include "trace.hpp"

namespace orc {

static const bool tracking_ = true;

uint64_t Pipe::Unique_ = 0;

static std::set<Pipe *> pipes_;
static std::mutex mutex_;

void Pipe::Insert(Pipe *pipe) {
    if (!tracking_)
        return;
    std::unique_lock<std::mutex> lock(mutex_);
    pipes_.insert(pipe);
}

void Pipe::Remove(Pipe *pipe) {
    if (!tracking_)
        return;
    std::unique_lock<std::mutex> lock(mutex_);
    pipes_.erase(pipe);
}

static struct SetupTracker { SetupTracker() {
    if (!tracking_)
        return;
    std::thread([]() {
        for (;;) {
            sleep(5);

            std::unique_lock<std::mutex> lock(mutex_);
            Log() << "^^^^^^^^^^^^^^^^" << std::endl;
            for (auto pipe : pipes_)
                Log() << std::setw(5) << pipe->unique_ << ": " << boost::core::demangle(typeid(*pipe).name()) << std::endl;
            Log() << "vvvvvvvvvvvvvvvv" << std::endl;
        }
    }).detach();
} } SetupTracker;

}
