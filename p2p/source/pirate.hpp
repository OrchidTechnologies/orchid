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


#ifndef ORCHID_PIRATE_HPP
#define ORCHID_PIRATE_HPP

// http://bloglitb.blogspot.com/2010/07/access-to-private-members-thats-easy.html

namespace orc {

template <typename Tag_>
struct Loot {
    typedef typename Tag_::type type;
    static type pointer;
};

template <typename Tag_>
typename Loot<Tag_>::type Loot<Tag_>::pointer;

template <typename Tag_, typename Tag_::type Pointer_>
struct Pirate : Loot<Tag_> {
    struct Value {
        Value() { Loot<Tag_>::pointer = Pointer_; }
    };
    static Value value;
};

template <typename Tag_, typename Tag_::type Pointer_>
typename Pirate<Tag_, Pointer_>::Value Pirate<Tag_, Pointer_>::value;

}

#endif//ORCHID_PIRATE_HPP
