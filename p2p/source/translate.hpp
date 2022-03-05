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


#ifndef ORCHID_TRANSLATE_HPP
#define ORCHID_TRANSLATE_HPP

#include "base.hpp"
#include "bearer.hpp"
#include "notation.hpp"

namespace orc {

std::string Bearer(const std::string &aud, const Object &account, const std::map<std::string, std::string> &claims = {}) {
    return Bearer(aud, Str(account.at("client_email")), "RS256", Str(account.at("private_key_id")), Str(account.at("private_key")), claims);
}

task<std::string> Translate(const S<Base> &base, const Object &account, const std::string &content, const std::string &target, const std::string &source) {
    co_return Str(Parse((co_await base->Fetch("POST", {{"https", "translate.googleapis.com", "443"}, "/v3/projects/" + Str(account.at("project_id")) + ":translateText"}, {
        {"authorization", "Bearer " + Bearer("https://translate.googleapis.com/", account, {{"sub", Str(account.at("client_email"))}})},
        {"content-type", "application/json"},
    }, Unparse({
        {"contents", {content}},
        {"target_language_code", target},
        {"source_language_code", source},
    }))).ok()).as_object().at("translations").at(0).at("translatedText"));
}

}

#endif//ORCHID_TRANSLATE_HPP
