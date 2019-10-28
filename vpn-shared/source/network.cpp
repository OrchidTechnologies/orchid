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


#include "client.hpp"
#include "endpoint.hpp"
#include "local.hpp"
#include "network.hpp"
#include "remote.hpp"

namespace orc {

Network::Network(Address directory, Address location, const std::string &rpc) :
    directory_(std::move(directory)),
    location_(std::move(location)),
    locator_(Locator::Parse(rpc))
{
    generator_.seed(boost::random::random_device()());
}

Network::Network(boost::program_options::variables_map &args) :
    Network(Address(args["eth-directory"].as<std::string>()), Address(args["eth-location"].as<std::string>()), args["rpc"].as<std::string>())
{
}

task<void> Network::Random(Sunk<> *sunk, const S<Origin> &origin, const std::string &pot) {
    Endpoint endpoint(origin, locator_);

    auto latest(co_await endpoint.Latest());
    //auto block(co_await endpoint.Header(latest));

    typedef std::tuple<std::string, U<rtc::SSLFingerprint>> Descriptor;
    auto [url, fingerprint] = co_await [&]() -> task<Descriptor> {
        //co_return Descriptor{"https://local.saurik.com:8443/", rtc::SSLFingerprint::CreateUniqueFromRfc4572("sha-256", "A9:E2:06:F8:42:C2:2A:CC:0D:07:3C:E4:2B:8A:FD:26:DD:85:8F:04:E0:2E:90:74:89:93:E2:A5:58:53:85:15")};
        //co_return Descriptor{"https://mac.saurik.com:8082/", rtc::SSLFingerprint::CreateUniqueFromRfc4572("sha-256", "A9:E2:06:F8:42:C2:2A:CC:0D:07:3C:E4:2B:8A:FD:26:DD:85:8F:04:E0:2E:90:74:89:93:E2:A5:58:53:85:15")};

        static Selector<Address, uint128_t> scan("scan");
        auto address = co_await scan.Call(endpoint, latest, directory_, generator_());
        orc_assert(address != 0);

        static Selector<std::tuple<uint256_t, std::string, std::string>, Address> look("look");
        auto [set, url, tls] = co_await look.Call(endpoint, latest, location_, address);

        auto space(tls.find(' '));
        orc_assert(space != std::string::npos);

        co_return Descriptor{url, rtc::SSLFingerprint::CreateUniqueFromRfc4572(tls.substr(0, space), tls.substr(space + 1))};
    }();

    orc_assert(fingerprint != nullptr);
    auto server(sunk->Wire<Server>(pot, std::move(fingerprint)));
    co_await server->Connect(origin, url);
}

task<S<Origin>> Network::Setup() {
    S<Origin> origin(GetLocal());

    for (unsigned i(0); i != 3; ++i) {
        auto remote(Break<Sink<Remote>>());
        co_await Random(remote.get(), origin, "");
        origin = remote;
    }

    co_return origin;
}

}
