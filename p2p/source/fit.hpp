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


#ifndef ORCHID_FIT_HPP
#define ORCHID_FIT_HPP

#include "error.hpp"

namespace orc {

template <typename Value_>
class Fit {
  private:
    const Value_ value_;

  public:
    inline Fit(Value_ value) :
        value_(value)
    {
    }

    template <typename Type_>
    inline operator Type_() {
        orc_assert(value_ <= std::numeric_limits<Type_>::max());
        return Type_(value_);
    }
};

}

#endif//ORCHID_FIT_HPP
