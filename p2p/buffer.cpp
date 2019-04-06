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


#include <iomanip>

#include "trace.hpp"
#include "buffer.hpp"

namespace orc {

size_t Buffer::size() const {
    size_t value(0);
    each([&](const Region &region) {
        value += region.size();
    });
    return value;
}

std::string Buffer::str() const {
    std::string value;
    value.resize(size());
    auto data(&value[0]);
    each([&](const Region &region) {
        auto size(region.size());
        memcpy(data, region.data(), size);
        data += size;
    });
    return value;
}

std::ostream &operator <<(std::ostream &out, const Buffer &buffer) {
    out << '{';
    buffer.each([&](const Region &region) {
        auto data(region.data());
        auto size(region.size());
        out << std::setfill('0');
        out << std::setbase(16);
        for (size_t i(0); i != size; ++i)
            out << std::setw(2) << int(data[i]);
        out << ',';
    });
    out << '}';
    return out;
}

Beam::Beam(const Buffer &buffer) :
    Beam(buffer.size())
{
    auto data(data_ + 1);
    buffer.each([&](const Region &region) {
        auto size(region.size());
        memcpy(data, region.data(), size);
        data += size;
    });
}

}
