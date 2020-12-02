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


#ifndef ORCHID_MARKUP_HPP
#define ORCHID_MARKUP_HPP

#include <sstream>

#include <boost/algorithm/string/replace.hpp>

namespace orc {

class Markup {
  private:
    std::ostringstream data_;

    std::string Escape(std::string text) {
        boost::replace_all(text, "&", "&amp;");
        boost::replace_all(text, "<", "&lt;");
        return text;
    }

  public:
    Markup(const std::string &title) { data_ <<
        "<!DOCTYE html>"
        "<html><head>"
            "<title>" << Escape(title) << "</title>"
            "<style type='text/css'>"
                "body {"
                    "font-family: monospace;"
                    "white-space: pre-wrap;"
                "}"
            "</style>"
        "</head><body>"
    ; }

    std::string operator()() {
        data_ << "</body></html>";
        auto data(data_.str());
        data_.clear();
        return data;
    }

    Markup &operator <<(std::string text) {
        data_ << Escape(std::move(text));
        return *this;
    }
};

}

#endif//ORCHID_MARKUP_HPP
