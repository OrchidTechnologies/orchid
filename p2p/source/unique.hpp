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


#ifndef ORCHID_UNIQUE_HPP
#define ORCHID_UNIQUE_HPP

#include "buffer.hpp"

namespace orc {

class Unique {
  private:
    Brick<16> data_;

  public:
    Unique();
    Unique(const Brick<16> &data);
    Unique(std::string value);

    Unique(const Unique &unique) = default;

    static Unique New();

    std::string str() const;

    inline bool operator <(const Unique &unique) const {
        return data_ < unique.data_;
    }
};

}

#endif//ORCHID_UNIQUE_HPP
