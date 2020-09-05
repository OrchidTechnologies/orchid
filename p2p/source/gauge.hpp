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


#ifndef ORCHID_GAUGE_HPP
#define ORCHID_GAUGE_HPP

#include <map>

#include "integer.hpp"
#include "shared.hpp"
#include "updater.hpp"

namespace orc {

class Origin;

static const uint256_t Gwei(1000000000);

class Gauge {
  private:
    typedef std::map<unsigned, double> Prices_;

    static task<S<Prices_>> Update_(Origin &origin);
    S<Updated<S<Prices_>>> prices_;

  public:
    Gauge(unsigned milliseconds, const S<Origin> &origin) :
        prices_(Wait(Opened(Update(milliseconds, [origin]() -> task<S<Prices_>> {
            co_return co_await Update_(*origin);
        }, "Gauge"))))
    {
    }

    task<void> Open() {
        co_return co_await prices_->Open();
    }

    S<Prices_> Prices() const {
        return (*prices_)();
    }

    uint256_t Price() const;
};

}

#endif//ORCHID_GAUGE_HPP
