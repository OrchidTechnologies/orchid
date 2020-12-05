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


#include <regex>

#include <eEVM/util.h>

#include "crypto.hpp"
#include "error.hpp"
#include "jsonrpc.hpp"

namespace orc {

Address::Address(const std::string &address) :
    uint160_t(address)
{
    static const std::regex re("0x[0-9a-fA-F]{40}");
    orc_assert_(std::regex_match(address, re), "invalid address " << address);
    //orc_assert(eevm::is_checksum_address(address));
}

Address::Address(const char *address) :
    uint160_t(std::string(address))
{
}

Address::Address(const Brick<64> &common) :
    Address(HashK(common).skip<12>().num<uint160_t>())
{
}

std::string Address::str() const {
    return eevm::to_checksum_address(Number<uint256_t>(num()).num<eevm::Address>());
}

}
