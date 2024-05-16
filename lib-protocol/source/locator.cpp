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


#include <skyr/url.hpp>

#include "error.hpp"
#include "locator.hpp"

namespace orc {

std::ostream &operator <<(std::ostream &out, const Origin &origin) {
    return out << origin.scheme_ << "://" << origin.host_ << ":" << origin.port_;
}

Locator::Locator(const std::string_view &locator) :
    Locator(std::string(locator))
{
}

Locator::Locator(const std::string &locator) :
    Locator([&]() {
        // XXX: this should obviously take std::string_view
        auto result(skyr::make_url(locator));
        orc_assert_(result, make_error_code(result.error()).message());
        auto &value(result.value());
        auto scheme(value.protocol());
        orc_assert(!scheme.empty() && scheme[scheme.size() - 1] == ':');
        scheme.resize(scheme.size() - 1);
        auto port(value.port());
        if (port.empty())
            port = std::to_string(skyr::url::default_port(scheme).value_or(0));
        return Locator(Origin(std::move(scheme), value.hostname(), port), value.pathname() + value.search());
    }())
{
}

std::ostream &operator <<(std::ostream &out, const Locator &locator) {
    return out << locator.origin_ << locator.path_;
}

}
