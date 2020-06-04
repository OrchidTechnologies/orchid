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


#include <cstdlib>

extern "C" {
#include <wireguard_ffi.h>
}

#include "boring.hpp"
#include "forge.hpp"
#include "sleep.hpp"

namespace orc {

void Boring::Error() {
    Log() << "WIREGUARD_ERROR" << std::endl;
}

void Boring::Land(const Buffer &data) {
    Beam input(data);

    for (;;) {
        Beam output(65536);
        const auto result(wireguard_read(wireguard_, input.data(), input.size(), output.data(), output.size()));
        switch (result.op) {
            case WIREGUARD_DONE:
                return;

            case WRITE_TO_NETWORK: {
                nest_.Hatch([&]() noexcept { return [this, data = std::move(output), size = result.size]() -> task<void> {
                    co_await Inner().Send(data.subset(0, size));
                }; });
                input.clear();
                continue;
            } break;

            case WIREGUARD_ERROR: {
                Error();
                return;
            } break;

            case WRITE_TO_TUNNEL_IPV4: {
                Span span(output.data(), output.size());
                const auto remote(ForgeIP4(span, &openvpn::IPv4Header::daddr, local_));
                orc_assert_(remote == remote_, "packet to " << Host(remote) << " != " << Host(remote_));
                return Link::Land(output.subset(0, result.size));
            } break;

            case WRITE_TO_TUNNEL_IPV6:
                orc_insist(false);
        }
    }
}

void Boring::Stop(const std::string &error) noexcept {
    return Link::Stop(error);
}

Boring::Boring(BufferDrain &drain, uint32_t local, const Host &remote, const std::string &secret, const std::string &common) :
    Link(drain),
    local_(local),
    remote_(remote),
    wireguard_(new_tunnel(secret.c_str(), common.c_str(), [](const char *message) {
        Log() << "WireGuard: " << message << std::endl;
    }, ALL))
{
}

Boring::~Boring() {
    tunnel_free(wireguard_);
}

void Boring::Open() {
    // XXX: use the same joinable thing I end up using in Transport
    Spawn([&]() noexcept -> task<void> {
        Beam output(148);
        while (!stop_) {
            const auto result(wireguard_tick(wireguard_, output.data(), output.size()));
            switch (result.op) {
                case WIREGUARD_DONE:
                    break;

                case WRITE_TO_NETWORK:
                    co_await Inner().Send(output.subset(0, result.size));
                    break;

                case WIREGUARD_ERROR:
                    Error();
                    break;

                case WRITE_TO_TUNNEL_IPV4:
                case WRITE_TO_TUNNEL_IPV6:
                    orc_insist(false);
            }

            co_await Sleep(100);
        }

        done_();
    });
}

task<void> Boring::Shut() noexcept {
    stop_ = true;
    co_await nest_.Shut();
    co_await Sunken::Shut();
    co_await done_.Wait();
    co_await Link::Shut();
}

task<void> Boring::Send(const Buffer &data) {
    Beam input(data);

    Span span(input.data(), input.size());
    const auto local(ForgeIP4(span, &openvpn::IPv4Header::saddr, remote_));
    orc_assert_(local == local_, "packet from " << Host(local) << " != " << Host(local_));

    Beam output(std::max<size_t>(input.size() + 32, 148));
    const auto result(wireguard_write(wireguard_, input.data(), input.size(), output.data(), output.size()));
    switch (result.op) {
        case WIREGUARD_DONE:
            break;

        case WRITE_TO_NETWORK:
            co_await Inner().Send(output.subset(0, result.size));
            break;

        case WIREGUARD_ERROR:
            Error();
            break;

        case WRITE_TO_TUNNEL_IPV4:
        case WRITE_TO_TUNNEL_IPV6:
            orc_insist(false);
    }
}

}
