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

#include "buffer.hpp"
#include "trace.hpp"

namespace orc {

size_t Buffer::size() const {
    size_t value(0);
    each([&](const uint8_t *data, size_t size) {
        value += size;
        return true;
    });
    return value;
}

bool Buffer::have(size_t value) const {
    return !each([&](const uint8_t *data, size_t size) {
        if (value <= size)
            return false;
        value -= size;
        return true;
    });
}

std::string Buffer::str() const {
    std::string value;
    value.resize(size());
    copy(&value[0], value.size());
    return value;
}

std::string Buffer::hex() const {
    std::ostringstream value;
    value << "0x" << std::hex << std::setfill('0');
    each([&](const uint8_t *data, size_t size) {
        for (size_t i(0), e(size); i != e; ++i)
            value << std::setw(2) << unsigned(data[i]);
        return true;
    });
    return value.str();
}

size_t Buffer::copy(uint8_t *data, size_t size) const {
    auto here(data);

    each([&](const uint8_t *next, size_t writ) {
        orc_assert(data + size - here >= writ);
        memcpy(here, next, writ);
        here += writ;
        return true;
    });

    return here - data;
}

std::ostream &operator <<(std::ostream &out, const Buffer &buffer) {
    out << '{';
    bool comma(false);
    buffer.each([&](const uint8_t *data, size_t size) {
        if (comma)
            out << ',';
        else
            comma = true;
        out << std::setfill('0');
        out << std::setbase(16);
        for (size_t i(0); i != size; ++i)
            out << std::setw(2) << int(data[i]);
        return true;
    });
    out << '}';
    return out;
}

Beam::Beam(const Buffer &buffer) :
    Beam(buffer.size())
{
    buffer.copy(data_, size_);
}

static uint8_t Bless(char value) {
    if (value >= '0' && value <= '9')
        return value - '0';
    if (value >= 'a' && value <= 'f')
        return value - 'a' + 10;
    if (value >= 'A' && value <= 'F')
        return value - 'A' + 10;
    orc_assert(false);
}

Beam Bless(const std::string &data) {
    size_t size(data.size());
    orc_assert((size & 1) == 0);
    size >>= 1;

    if (size == 0)
        return Beam();

    size_t offset;
    if (data[0] != '0' || data[1] != 'x') {
        offset = 0;
    } else {
        offset = 2;
        --size;
    }

    Beam beam(size);
    for (size_t i(0); i != size; ++i)
        beam[i] = (Bless(data[offset + i * 2]) << 4) + Bless(data[offset + i * 2 + 1]);
    return beam;
}

bool operator ==(const Beam &lhs, const Buffer &rhs) {
    auto here(lhs.data());
    auto left(lhs.size());

    return rhs.each([&](const uint8_t *data, size_t size) {
        if (size > left || memcmp(here, data, size) != 0)
            return false;
        here += size;
        left -= size;
        return true;
    }) && here == lhs.data() + lhs.size();
}

}
