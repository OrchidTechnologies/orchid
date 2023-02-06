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


#ifndef ORCHID_QUERY_HPP
#define ORCHID_QUERY_HPP

#include <string>

#include <dns.h>

namespace orc {

class Query {
  private:
    dns_decoded_t data_[DNS_DECODEBUF_4K];

  public:
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-member-init)
    Query(const Span<const uint8_t> &data) {
        size_t size(sizeof(data_));
        orc_assert(dns_decode(data_, &size, reinterpret_cast<const dns_packet_t *>(data.data()), data.size()) == RCODE_OKAY);
    }

    Query(const std::string &data) :
        Query(Span(reinterpret_cast<const uint8_t *>(data.data()), data.size()))
    {
    }

    const dns_query_t *operator ->() const {
        return reinterpret_cast<const dns_query_t *>(data_);
    }

    std::string name() const {
        const auto query(operator ->());
        // https://stackoverflow.com/questions/32031349/what-does-qd-stand-for-in-dns-rfc1035
        orc_assert(query->qdcount == 1);
        std::string value(query->questions[0].name);
        value.pop_back();
        return value;
    }
};

}

#endif//ORCHID_QUERY_HPP
