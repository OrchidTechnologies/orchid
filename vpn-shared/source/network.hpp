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


#ifndef ORCHID_NETWORK_HPP
#define ORCHID_NETWORK_HPP

#include <boost/random.hpp>
#include <boost/random/random_device.hpp>

#include "base.hpp"
#include "chain.hpp"
#include "provider.hpp"
#include "valve.hpp"

namespace orc {

struct Stake {
    uint256_t amount_;
    Maybe<std::string> url_;

    Stake(uint256_t amount, Maybe<std::string> url) :
        amount_(std::move(amount)),
        url_(std::move(url))
    {
    }
};

class Network :
    public Valve
{
  private:
    const S<Chain> chain_;
    const Address directory_;
    const Address location_;

    boost::random::independent_bits_engine<boost::mt19937, 128, uint128_t> generator_;

  public:
    Network(S<Chain> chain, Address directory, Address location);

    Network(const Network &) = delete;
    Network(Network &&) = delete;

    void Open();
    task<void> Shut() noexcept override;

    task<std::map<Address, Stake>> Scan();

    task<Provider> Select(const std::string &name, const Address &provider);
};

}

#endif//ORCHID_NETWORK_HPP
