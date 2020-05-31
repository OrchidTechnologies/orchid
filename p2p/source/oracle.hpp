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


#ifndef ORCHID_ORACLE_HPP
#define ORCHID_ORACLE_HPP

#include <string>

#include "float.hpp"
#include "locked.hpp"
#include "task.hpp"
#include "valve.hpp"

namespace orc {

static const uint256_t Gwei(1000000000);

class Oracle :
    public Valve
{
  private:
    const std::string currency_;

    struct Fiat_ {
        Float eth_ = 0;
        Float oxt_ = 0;
    }; Locked<Fiat_> fiat_;

    typedef std::map<unsigned long, double> Prices_;
    Locked<S<const Prices_>> prices_;

    task<void> UpdateCoin(Origin &origin);
    task<void> UpdateGas(Origin &origin);

  public:
    Oracle(std::string currency);

    void Open(S<Origin> origin);
    task<void> Shut() noexcept override;

    Fiat_ Fiat() const;
    S<const Prices_> Prices() const;
};

}

#endif//ORCHID_ORACLE_HPP
