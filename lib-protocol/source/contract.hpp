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
 * MERCHANTABILITY or CONTRACTNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */


#ifndef ORCHID_CONTRACT_HPP
#define ORCHID_CONTRACT_HPP

#include "address.hpp"

namespace orc {

// XXX: this should be constexpr (c++2b maybe?)

static const Address Directory_("0x918101FB64f467414e9a785aF9566ae69C3e22C5");
static const Address Locator_("0xEF7bc12e0F6B02fE2cb86Aa659FdC3EBB727E0eD");

static const Address Lottery0_("0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1");
static const Address Lottery1_("0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82");

}

#endif//ORCHID_CONTRACT_HPP
