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


#include <sstream>

#include <boost/algorithm/string/erase.hpp>

#include "crypto.hpp"
#include "unique.hpp"

namespace orc {

Unique::Unique() :
    data_(Zero<16>())
{
}

Unique::Unique(const Brick<16> &data) :
    data_(data)
{
    data_[6] = 0x40 | data_[6] & 0x0f;
    data_[8] = 0x80 | data_[8] & 0x3f;
}

Unique::Unique(std::string value) {
    boost::erase_all(value, "-");
    data_ = Bless(value);
}

Unique Unique::New() {
    return Random<16>();
}

std::string Unique::str() const {
    // XXX: this is super inefficient
    std::ostringstream data;
    data << data_.subset(0, 4).hex(false) << '-' << data_.subset(4, 2).hex(false) << '-' << data_.subset(6, 2).hex(false) << '-' << data_.subset(8, 2).hex(false) << '-' << data_.subset(10, 6).hex(false);
    return data.str();
}

}
