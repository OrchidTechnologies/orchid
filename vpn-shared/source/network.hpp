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


#ifndef ORCHID_NETWORK_HPP
#define ORCHID_NETWORK_HPP

#include <boost/random.hpp>
#include <boost/random/random_device.hpp>

#include "jsonrpc.hpp"
#include "locator.hpp"
#include "origin.hpp"

namespace orc {

class Network {
  private:
    const Locator locator_;
    const Address directory_;
    const Address location_;

    boost::random::independent_bits_engine<boost::mt19937, 128, uint128_t> generator_;

  public:
    Network(const std::string &rpc, Address directory, Address location);

    task<void> Random(Sunk<> *sunk, const S<Origin> &origin, const std::string &name, const Address &provider, Address lottery, uint256_t chain, const Secret &secret, Address funder);
};

}

#endif//ORCHID_NETWORK_HPP
