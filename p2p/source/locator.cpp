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


#include <skyr/url.hpp>

#include "error.hpp"
#include "locator.hpp"

namespace orc {

Locator Locator::Parse(const std::string &url) {
    auto base(skyr::make_url(url));
    orc_assert_(base, base.error().message());
    auto &value(base.value());
    auto scheme(value.protocol());
    orc_assert(!scheme.empty() && scheme[scheme.size() - 1] == ':');
    scheme.resize(scheme.size() - 1);
    auto port(value.port());
    if (port.empty())
        port = std::to_string(skyr::url::default_port(scheme).value_or(0));
    return Locator(std::move(scheme), value.hostname(), port, value.pathname());
}

}
