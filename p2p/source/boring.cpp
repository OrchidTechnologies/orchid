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


#include <cstdlib>

#include <boost/algorithm/string.hpp>
#include <boost/property_tree/ini_parser.hpp>

extern "C" {
#include <wireguard_ffi.h>
}

#include "base.hpp"
#include "boring.hpp"
#include "fit.hpp"
#include "forge.hpp"
#include "sleep.hpp"
#include "trace.hpp"

namespace orc {

void Boring::Error() {
    Log() << "WIREGUARD_ERROR" << std::endl;
}

void Boring::Land(const Buffer &data) {
    Flat input(data);

    for (;;) {
        Beam output(65536);
        const auto result(wireguard_read(wireguard_, input.data(), Fit(input.size()), output.data(), Fit(output.size())));
        switch (result.op) {
            case WIREGUARD_DONE:
                return;

            case WRITE_TO_NETWORK: {
                nest_.Hatch([&]() noexcept { return [this, data = std::move(output), size = result.size]() -> task<void> {
                    co_await Inner().Send(data.subset(0, size));
                }; }, __FUNCTION__);
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

Boring::Boring(BufferDrain &drain, const S<Base> &base, uint32_t local, const Host &remote, const std::string &secret, const std::string &common) :
    Link(typeid(*this).name(), drain),
    base_(base),
    local_(local),
    remote_(remote),
    wireguard_(new_tunnel(secret.c_str(), common.c_str(), 0, 0, [](const char *message) {
        Log() << "WireGuard: " << message << std::endl;
    }, TRACE))
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
            const auto result(wireguard_tick(wireguard_, output.data(), Fit(output.size())));
            switch (result.op) {
                case WIREGUARD_DONE:
                    break;

                case WRITE_TO_NETWORK:
                    nest_.Hatch([&]() noexcept { return [this, data = std::move(output), size = result.size]() -> task<void> {
                        co_await Inner().Send(data.subset(0, size));
                    }; }, __FUNCTION__);
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
    }, __FUNCTION__);
}

task<void> Boring::Shut() noexcept {
    stop_ = true;
    co_await nest_.Shut();
    co_await Sunken::Shut();
    co_await *done_;
    co_await Link::Shut();
}

task<void> Boring::Send(const Buffer &data) {
    Beam input(data);

    Span span(input.data(), input.size());
    const auto local(ForgeIP4(span, &openvpn::IPv4Header::saddr, remote_));
    orc_assert_(local == local_, "packet from " << Host(local) << " != " << Host(local_));

    Beam output(std::max<size_t>(input.size() + 32, 148));
    const auto result(wireguard_write(wireguard_, input.data(), Fit(input.size()), output.data(), Fit(output.size())));
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

task<void> Guard(BufferSunk &sunk, S<Base> base, uint32_t local, std::string file) {
    boost::property_tree::ptree tree; {
        std::istringstream data(file);
        boost::property_tree::ini_parser::read_ini(data, tree);
    }

    const auto address([&]() {
        std::vector<std::string> addresses;
        boost::split(addresses, tree.get<std::string>("Interface.Address"), boost::is_any_of(","));
        for (auto &address : addresses) {
            while (!address.empty() && address[0] == ' ')
                address = address.substr(1);
            while (!address.empty() && address[address.size() - 1] == ' ')
                address = address.substr(0, address.size() - 1);
            const auto slash(address.find('/'));
            if (slash != std::string::npos)
                address = address.substr(0, slash);
            Host host(address);
            if (host.v4())
                return host;
        }
        orc_assert_(false, "no IPv4 in Interface.Address");
    }());

    const auto endpoint(tree.get<std::string>("Peer.Endpoint"));
    const auto colon(endpoint.find(':'));
    orc_assert(colon != std::string::npos);
    const auto endpoints(co_await base->Resolve(endpoint.substr(0, colon), endpoint.substr(colon + 1)));
    orc_assert(!endpoints.empty());

    auto &boring(sunk.Wire<BufferSink<Boring>>(base, local, address, tree.get<std::string>("Interface.PrivateKey"), tree.get<std::string>("Peer.PublicKey")));
    co_await base->Associate(boring, endpoints[0]);
    boring.Open();
}

}
