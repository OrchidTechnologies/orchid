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
#include <set>

#include <unistd.h>

#include <boost/core/demangle.hpp>

#include "trace.hpp"
#include "valve.hpp"

namespace orc {

static const bool tracking_ = false;

uint64_t Valve::Unique_ = 0;

struct Tracker {
    std::mutex mutex_;
    std::set<Valve *> valves_;
};

class Track {
  private:
    Tracker &tracker_;
    std::unique_lock<std::mutex> lock_;

  public:
    Track() :
        tracker_([]() -> Tracker & {
            static Tracker tracker;

            static std::thread thread([]() {
                for (;;) {
                    sleep(5);

                    std::unique_lock<std::mutex> lock(tracker.mutex_);
                    Log() << "^^^^^^^^^^^^^^^^" << std::endl;
                    for (const auto valve : tracker.valves_)
                        Log() << std::setw(5) << valve->unique_ << ": " << boost::core::demangle(typeid(*valve).name()) << std::endl;
                    Log() << "vvvvvvvvvvvvvvvv" << std::endl;
                }
            });

            return tracker;
        }()),
        lock_(tracker_.mutex_)
    {
    }

    std::set<Valve *> *operator ->() {
        return &tracker_.valves_;
    }
};

void Valve::Insert(Valve *valve) {
    if (!tracking_)
        return;
    Track()->insert(valve);
}

void Valve::Remove(Valve *valve) {
    if (!tracking_)
        return;
    Track()->erase(valve);
}

}
