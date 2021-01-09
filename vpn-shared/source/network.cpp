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


#include <openssl/obj_mac.h>
#include <rtc_base/ssl_fingerprint.h>

#include "network.hpp"
#include "sequence.hpp"

namespace orc {

Network::Network(S<Chain> chain, Address directory, Address location) :
    Valve(typeid(*this).name()),
    chain_(std::move(chain)),
    directory_(std::move(directory)),
    location_(std::move(location))
{
    generator_.seed(boost::random::random_device()());
}

void Network::Open() {
}

task<void> Network::Shut() noexcept {
    co_await Valve::Shut();
}

template <typename Code_>
task<void> Stakes(const S<Chain> &chain, const Address &directory, const Block &block, const uint256_t &storage, const uint256_t &primary, const Code_ &code) {
    if (primary == 0)
        co_return;

    const auto stake(HashK(Tie(primary, uint256_t(0x2U))).num<uint256_t>());
    const auto [left, right, stakee, amount, delay] = co_await chain->Get(block, directory, storage, stake + 6, stake + 7, stake + 4, stake + 2, stake + 3);
    orc_assert(amount != 0);

    *co_await Parallel(
        Stakes(chain, directory, block, storage, left, code),
        Stakes(chain, directory, block, storage, right, code),
        code(uint160_t(stakee), amount, delay));
}

template <typename Code_>
task<void> Stakes(const S<Chain> &chain, const Address &directory, const Code_ &code) {
    const auto height(co_await chain->Height());
    const auto block(co_await chain->Header(height));
    const auto [account, root] = co_await chain->Get(block, directory, nullptr, 0x3U);
    co_await Stakes(chain, directory, block, account.storage_, root, code);
}

task<std::map<Address, Stake>> Network::Scan() {
    cppcoro::async_mutex mutex;
    std::map<Address, uint256_t> stakes;

    co_await Stakes(chain_, directory_, [&](const Address &stakee, const uint256_t &amount, const uint256_t &delay) -> task<void> {
        std::cout << "DELAY " << stakee << " " << std::dec << delay << " " << std::dec << amount << std::endl;
        if (delay < 90*24*60*60)
            co_return;
        const auto lock(co_await mutex.scoped_lock_async());
        stakes[stakee] += amount;
    });

    // XXX: Zip doesn't work if I inline this argument
    const auto urls(co_await Parallel(Map([&](const auto &stake) {
        return [&](Address provider) -> Task<std::string> {
            static const Selector<std::tuple<uint256_t, Bytes, Bytes, Bytes>, Address> look_("look");
            const auto &[set, url, tls, gpg] = co_await look_.Call(*chain_, "latest", location_, 90000, provider);
            orc_assert(set != 0);
            co_return url.str();
        }(stake.first);
    }, stakes)));

    std::map<Address, Stake> providers;

    // XXX: why can't I move things out of this iterator? (note: I did use auto)
    for (const auto &stake : Zip(urls, stakes))
        orc_assert(providers.try_emplace(stake.get<1>().first, stake.get<1>().second, stake.get<0>()).second);

    co_return providers;
}

task<Provider> Network::Select(const std::string &name, const Address &provider) {
    //co_return Provider{"0x2b1ce95573ec1b927a90cb488db113b40eeb064a", "https://local.saurik.com:8084/", rtc::SSLFingerprint::CreateUniqueFromRfc4572("sha-256", "A9:E2:06:F8:42:C2:2A:CC:0D:07:3C:E4:2B:8A:FD:26:DD:85:8F:04:E0:2E:90:74:89:93:E2:A5:58:53:85:15")};

    // XXX: this adjustment is suboptimal; it seems to help?
    //const auto latest(co_await chain_.Latest() - 1);
    //const auto block(co_await chain_.Header(latest));
    // XXX: Cloudflare's servers are almost entirely broken
    static const std::string latest("latest");

    // XXX: parse the / out of name (but probably punt this to the frontend)
    Beam argument;
    const auto curator(co_await chain_->Resolve(latest, name));

    const auto address(co_await [&]() -> task<Address> {
        if (provider != Address(0))
            co_return provider;

        static const Selector<std::tuple<Address, uint128_t>, uint128_t> pick_("pick");
        const auto [address, delay] = co_await pick_.Call(*chain_, latest, directory_, 90000, generator_());
        orc_assert(delay >= 90*24*60*60);
        co_return address;
    }());

    static const Selector<uint128_t, Address, Bytes> good_("good");
    static const Selector<std::tuple<uint256_t, Bytes, Bytes, Bytes>, Address> look_("look");

    const auto [good, look] = *co_await Parallel(
        good_.Call(*chain_, latest, curator, 90000, address, argument),
        look_.Call(*chain_, latest, location_, 90000, address));
    const auto &[set, url, tls, gpg] = look;

    orc_assert(good != 0);
    orc_assert(set != 0);

    Window window(tls);
    orc_assert(window.Take() == 0x06);
    window.Skip(Length(window));
    const Beam fingerprint(window);

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
    co_return Provider{address, url.str(), std::make_shared<rtc::SSLFingerprint>(algorithm->second, fingerprint.data(), fingerprint.size())};
}

}
