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


#ifndef ORCHID_UPDATED_HPP
#define ORCHID_UPDATED_HPP

#include "locked.hpp"
#include "task.hpp"

namespace orc {

template <typename Type_>
class Updated {
  protected:
    Locked<Type_> value_;

  public:
    Updated() = default;

    Updated(Type_ &&value) :
        value_(std::move(value))
    {
    }

    Type_ operator()() const {
        return *value_();
    }

    virtual task<void> Update() = 0;
    virtual Task<void> Open() = 0;
};

}

#endif//ORCHID_UPDATED_HPP
