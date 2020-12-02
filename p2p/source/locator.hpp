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


#ifndef ORCHID_LOCATOR_HPP
#define ORCHID_LOCATOR_HPP

#include <string>

namespace orc {

struct Locator final {
    std::string scheme_;
    std::string host_;
    std::string port_;
    std::string path_;

    Locator(const std::string &locator);

    Locator(const char *locator) :
        Locator(std::string(locator))
    {
    }

    Locator(std::string scheme, std::string host, std::string port, std::string path) :
        scheme_(std::move(scheme)),
        host_(std::move(host)),
        port_(std::move(port)),
        path_(std::move(path))
    {
    }

    auto Tuple() const {
        return std::tie(scheme_, host_, port_, path_);
    }

    bool operator <(const Locator &rhs) const {
        return Tuple() < rhs.Tuple();
    }

    Locator operator +(const char *path) const {
        return {scheme_, host_, port_, path_ + path};
    }
};

std::ostream &operator <<(std::ostream &out, const Locator &locator);

}

#endif//ORCHID_LOCATOR_HPP
