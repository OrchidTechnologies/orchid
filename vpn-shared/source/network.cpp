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


#include <openssl/obj_mac.h>

#include "client.hpp"
#include "endpoint.hpp"
#include "ens.hpp"
#include "local.hpp"
#include "network.hpp"
#include "sleep.hpp"

namespace orc {

Network::Network(const std::string &rpc, Address directory, Address location) :
    locator_(Locator::Parse(rpc)),
    directory_(std::move(directory)),
    location_(std::move(location))
{
    generator_.seed(boost::random::random_device()());
}

task<void> Network::Random(Sunk<> *sunk, const S<Origin> &origin, const std::string &name, const Address &provider, Address lottery, uint256_t chain, const Secret &secret, Address funder) {
    const Endpoint endpoint(origin, locator_);

    // XXX: this adjustment is suboptimal; it seems to help?
    const auto latest(co_await endpoint.Latest() - 1);
    //const auto block(co_await endpoint.Header(latest));

    typedef std::tuple<Address, std::string, U<rtc::SSLFingerprint>> Descriptor;
    auto [address, url, fingerprint] = co_await [&]() -> task<Descriptor> {
        //static const Address address("0x2b1ce95573ec1b927a90cb488db113b40eeb064a");
        //co_return Descriptor{address, "https://local.saurik.com:8443/", rtc::SSLFingerprint::CreateUniqueFromRfc4572("sha-256", "A9:E2:06:F8:42:C2:2A:CC:0D:07:3C:E4:2B:8A:FD:26:DD:85:8F:04:E0:2E:90:74:89:93:E2:A5:58:53:85:15")};
        //co_return Descriptor{address, "https://mac.saurik.com:8084/", rtc::SSLFingerprint::CreateUniqueFromRfc4572("sha-256", "A9:E2:06:F8:42:C2:2A:CC:0D:07:3C:E4:2B:8A:FD:26:DD:85:8F:04:E0:2E:90:74:89:93:E2:A5:58:53:85:15")};

        static const Address ens("0x314159265dd8dbb310642f98f50c066173c1259b");

        // XXX: parse the / out of name (but probably punt this to the frontend)
        const auto node(Name(name));
        Beam argument;

        static const Selector<Address, Bytes32> resolver_("resolver");
        const auto resolver(co_await resolver_.Call(endpoint, latest, ens, 90000, node));

        static const Selector<Address, Bytes32> addr_("addr");
        const auto curator(co_await addr_.Call(endpoint, latest, resolver, 90000, node));

        for (;;) try {
            static const Selector<std::tuple<Address, uint128_t>, uint128_t> pick_("pick");
            auto [address, delay] = co_await pick_.Call(endpoint, latest, directory_, 90000, generator_());
            orc_assert(address != 0);
            if (delay < 90*24*60*60)
                continue;

            // XXX: this is a stupid hack
            if (provider != 0)
                address = provider;

            static const Selector<uint128_t, Address, Bytes> good_("good");
            const auto adjust(co_await good_.Call(endpoint, latest, curator, 90000, address, argument));
            if (adjust < generator_())
                continue;

            static const Selector<std::tuple<uint256_t, Bytes, Bytes, Bytes>, Address> look_("look");
            const auto [set, url, tls, gpg] = co_await look_.Call(endpoint, latest, location_, 90000, address);

            Window window(tls);
            orc_assert(window.Take() == 0x06);
            window.Skip(Length(window));
            Beam fingerprint(window);

            static const std::map<Beam, std::string> algorithms_({
                {Object(NID_md2), "md2"},
                {Object(NID_md5), "md5"},
                {Object(NID_sha1), "sha-1"},
                {Object(NID_sha224), "sha-224"},
                {Object(NID_sha256), "sha-256"},
                {Object(NID_sha384), "sha-384"},
                {Object(NID_sha512), "sha-512"},
            });

            const auto algorithm(algorithms_.find(Window(tls).Take(tls.size() - fingerprint.size())));
            orc_assert(algorithm != algorithms_.end());
            co_return Descriptor{address, url.str(), std::make_unique<rtc::SSLFingerprint>(algorithm->second, fingerprint.data(), fingerprint.size())};
        } catch (const std::exception &error) {
            co_await Sleep(2);
        }
    }();

    orc_assert(fingerprint != nullptr);
    const auto client(sunk->Wire<Client>(std::move(fingerprint), std::move(address), std::move(lottery), std::move(chain), secret, std::move(funder)));
    co_await client->Open(origin, url);
}

}
