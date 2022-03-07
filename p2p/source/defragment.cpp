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


#include <openvpn/ip/csum.hpp>
#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/ipcommon.hpp>

#include "defragment.hpp"
#include "fit.hpp"
#include "scope.hpp"

namespace orc {

void Defragment::Land(const Buffer &data) {
    uint8_t first;
    data.snip(1).copy(&first, 1);
    switch (openvpn::IPCommon::version(first)) {
        case uint8_t(openvpn::IPCommon::IPv4): {
            // XXX: this is really slow :(
            Window window(data);
            openvpn::IPv4Header ip4;
            window.Take(&ip4);

            const uint16_t fragoff(boost::endian::big_to_native(ip4.frag_off));
            const auto offset(uint16_t(fragoff << 3));
            const auto flags(fragoff >> 13);
            const auto last((flags & 1) == 0);
            if (offset == 0 && last)
                return Link::Land(data);

            const auto size(boost::endian::big_to_native(ip4.tot_len));
            const auto header(openvpn::IPv4Header::length(ip4.version_len));
            window.Skip(header - sizeof(ip4));
            //Log() << "FRAG " << std::dec << size << " " << header << " " << data.size() << " " << flags << " " << offset << " " << ip4.id << std::endl;

            const Fragmented_ fragmented{ip4.saddr, ip4.daddr, ip4.protocol, ip4.id};
            if (fragmented_ != fragmented) {
                fragmented_ = fragmented;
                defragmented_.packet_.clear();
            }

            auto &defragmented(defragmented_);

            if (offset == 0)
                defragmented.header_ = data.snip(header).str();
            if (offset != defragmented.packet_.size())
                break;
            defragmented.packet_ += window.snip(size - header).str();

            if (last) {
                _scope({ defragmented_.packet_.clear(); });

                Span span(defragmented.header_.data(), defragmented.header_.size());
                auto header(span.cast<openvpn::IPv4Header>());
                header.tot_len = boost::endian::native_to_big(uint16_t(Fit(span.size() + defragmented.packet_.size())));
                header.frag_off = 0;
                header.check = 0;
                header.check = openvpn::IPChecksum::checksum(span.data(), span.size());

                //Log() << Tie(defragmented.header_, defragmented.packet_) << std::endl;
                return Link::Land(Tie(defragmented.header_, defragmented.packet_));
            }
        } break;

        default:
            return Link::Land(data);
        break;
    }
}

}
