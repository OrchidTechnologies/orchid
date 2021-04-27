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


#include <eEVM/util.h>

#include "address.hpp"
#include "ctre.hpp"
#include "error.hpp"

namespace orc {

using namespace ctre::literals;

Address::Address(const std::string_view &address) :
    uint160_t(address)
{
    orc_assert_("0x[0-9a-fA-F]{40}"_ctre.match(address), "invalid address " << address);
    //orc_assert(eevm::is_checksum_address(address));
}

Address::Address(const std::string &address) :
    Address(std::string_view(address))
{
}

Address::Address(const char *address) :
    Address(std::string_view(address))
{
}

Address::Address(const Key &key) :
    Address(HashK(ToUncompressed(key).skip<1>()).skip<12>().num<uint160_t>())
{
}

std::string Address::str() const {
    return eevm::to_checksum_address(Number<uint256_t>(num()).num<eevm::Address>());
}

}
