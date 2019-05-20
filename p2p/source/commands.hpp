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


#ifndef ORCHID_COMMANDS_HPP
#define ORCHID_COMMANDS_HPP

#include "link.hpp"

namespace orc {

static const Tag Zero{0x00000000};

static const Tag AnswerTag{0x22a2b0d0};
static const Tag BatchTag{0x6c53939e};
static const Tag CloseTag{0x81b978ae};
static const Tag ConnectTag{0xe7280b03};
static const Tag DiscardTag{0xf5d821c9};
static const Tag OfferTag{0xe3a99039};
static const Tag NegotiateTag{0x5d8a6d96};

}

#endif//ORCHID_COMMANDS_HPP
