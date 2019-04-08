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


#ifndef ORCHID_SHARED_HPP
#define ORCHID_SHARED_HPP

#include "link.hpp"

namespace orc {

static const Tag AssociateTag{93, 97, 102, 34};
static const Tag DeliverTag{246, 228, 17, 134};
static const Tag DissociateTag{87, 248, 93, 7};

static const Tag AnswerTag{34, 162, 176, 208};
static const Tag CancelTag{223, 49, 55, 9};
static const Tag ChannelTag{159, 32, 166, 189};
static const Tag CloseTag{129, 185, 120, 174};
static const Tag ConnectTag{231, 40, 11, 3};
static const Tag OfferTag{17, 59, 137, 94};
static const Tag NegotiateTag{188, 73, 31, 143};

}

#endif//ORCHID_SHARED_HPP
