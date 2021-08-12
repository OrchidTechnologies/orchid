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


#include "nested.hpp"

namespace orc {

void Nested::enc(std::string &data, size_t length) {
    if (length == 0)
        return;
    enc(data, length >> 8);
    data += char(length & 0xff);
}

void Nested::enc(std::string &data, size_t length, uint8_t offset) {
    if (length < 56)
        data += char(length + offset);
    else {
        std::string binary;
        enc(binary, length);
        data += char(binary.size() + offset + 55);
        data += binary;
    }
}

void Nested::enc(std::string &data) const {
    if (!scalar_) {
        std::string list;
        for (auto &item : array_)
            item.enc(list);
        enc(data, list.size(), 0xc0);
        data += list;
    } else if (value_.size() == 1 && uint8_t(value_[0]) < 0x80) {
        data += value_[0];
    } else {
        enc(data, value_.size(), 0x80);
        data += value_;
    }
}

std::string Implode(const Nested &nested) {
    std::string data;
    nested.enc(data);
    return data;
}

std::ostream &operator <<(std::ostream &out, const Nested &value) {
    if (!value.scalar()) {
        out << '[';
        for (size_t i(0), e(value.size()); i != e; ++i)
            out << char(i + (i < 10 ? '0' : 'A' - 10)) << ':' << value[i] << ',';
        out << ']';
    } else if ([&]() {
        return true;
    }()) {
        out << Subset(value.str());
    } else {
        out << '"';
        for (uint8_t c : value.str())
            if (c >= 0x20 && c < 0x80)
                out << c;
            else {
                out << std::hex << std::setfill('0');
                out << "\\x" << std::setw(2) << unsigned(c);
            }
        out << '"';
    }

    return out;
}

Nested Explode(Window &window) {
    const auto first(window.Take());

    // XXX: try to remove this local state
    bool scalar;
    std::string value;
    std::vector<Nested> array;

    if (first < 0x80) {
        scalar = true;
        value = char(first);
    } else if (first < 0xb8) {
        scalar = true;
        value.resize(first - 0x80);
        window.Take(value);
    } else if (first < 0xc0) {
        scalar = true;
        uint32_t length(0);
        const auto size(first - 0xb7);
        orc_assert(size <= sizeof(length));
        window.Take(sizeof(length) - size + reinterpret_cast<uint8_t *>(&length), size);
        value.resize(boost::endian::big_to_native(length));
        window.Take(value);
    } else if (first < 0xf8) {
        scalar = false;
        const auto beam(window.Take(first - 0xc0));
        Window sub(beam);
        while (!sub.done())
            array.emplace_back(Explode(sub));
    } else {
        scalar = false;
        uint32_t length(0);
        const auto size(first - 0xf7);
        orc_assert(size <= sizeof(length));
        window.Take(sizeof(length) - size + reinterpret_cast<uint8_t *>(&length), size);
        const auto beam(window.Take(boost::endian::big_to_native(length)));
        Window sub(beam);
        while (!sub.done())
            array.emplace_back(Explode(sub));
    }

    return Nested(scalar, std::move(value), std::move(array));
}

Nested Explode(Window &&window) {
    auto nested(Explode(window));
    orc_assert(window.done());
    return nested;
}

// XXX: "" should be {} once I fix Hash overloads
const Brick<32> EmptyScalar(HashK(""));
const Brick<32> EmptyVector(HashK(Implode({})));

}
