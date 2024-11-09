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


#ifndef ORCHID_ADDRESS_HPP
#define ORCHID_ADDRESS_HPP

#include "crypto.hpp"
#include "notation.hpp"

namespace orc {

// XXX: none of this is REMOTELY efficient

typedef boost::multiprecision::number<boost::multiprecision::cpp_int_backend<160, 160, boost::multiprecision::unsigned_magnitude, boost::multiprecision::unchecked, void>> uint160_t;

class Address :
    private uint160_t
{
  public:
    // XXX: this check is false positive here
    // NOLINTNEXTLINE(modernize-type-traits)
    using uint160_t::uint160_t;

    Address(const uint160_t &value) :
        uint160_t(value)
    {
    }

    Address(const Data<20> &data) :
        Address(data.num<uint160_t>())
    {
    }

    Address(const std::string_view &address);
    Address(const std::string &address);
    Address(const char *address);

    Address(const Key &key);

    const uint160_t &num() const {
        return static_cast<const uint160_t &>(*this);
    }

    bool operator <(const Address &rhs) const {
        return num() < rhs.num();
    }

    bool operator ==(const Address &rhs) const {
        return num() == rhs.num();
    }

    bool operator !=(const Address &rhs) const {
        return num() != rhs.num();
    }

    auto buf() const {
        return Number<uint160_t>(num());
    }

    std::string str() const;

    operator Argument() const {
        return buf();
    }
};

inline std::ostream &operator <<(std::ostream &out, const Address &address) {
    return out << address.str();
}

inline std::ostream &operator <<(std::ostream &out, const std::optional<Address> &address) {
    if (!address)
        return out << "(null)";
    return out << *address;
}

inline bool Each(const Address &address, const std::function<bool (const uint8_t *, size_t)> &code) {
    return address.buf().each(code);
}

template <size_t Index_, typename... Taking_>
struct Taking<Index_, Address, void, Taking_...> final {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    Number<uint160_t> value;
    window.Take(value);
    std::get<Index_>(tuple) = value.num<uint160_t>();
    return Taker<Index_ + 1, Taking_...>::Take(tuple, window, std::forward<Buffer_>(buffer));
} };

}

#endif//ORCHID_ADDRESS_HPP
