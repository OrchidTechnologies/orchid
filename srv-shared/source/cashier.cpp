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


#include <boost/multiprecision/cpp_bin_float.hpp>

#include <cppcoro/async_manual_reset_event.hpp>

#include "baton.hpp"
#include "cashier.hpp"
#include "duplex.hpp"
#include "json.hpp"
#include "sleep.hpp"
#include "structured.hpp"

namespace orc {

static Float Ten18("1000000000000000000");
static Float Two128(uint256_t(1) << 128);
//static Float Two30(1024 * 1024 * 1024);

static const auto Update_(Hash("Update(address,address,uint128,uint128,uint256)"));
static const auto Bound_(Hash("Update(address,address)"));

task<void> Cashier::Update() {
    auto eth(co_await Price("ETH", currency_, Ten18));
    orc_assert(eth != 0);

    auto oxt(co_await Price("OXT", currency_, Ten18));
    if (oxt == 0)
        oxt = eth / 300;

    //auto predict(Parse(co_await Request("GET", {"https", "ethgasstation.info", "443", "/json/predictTable.json"}, {}, {})));

    const auto prices(prices_());
    prices->eth_ = std::move(eth);
    prices->oxt_ = std::move(oxt);
}

task<void> Cashier::Look(const Address &signer, const Address &funder, const std::string &combined) {
    static const auto look(Hash("look(address,address)").Clip<4>().num<uint32_t>());
    Builder builder;
    Coder<Address, Address>::Encode(builder, funder, signer);
    co_await station_->Send("eth_call", 'C' + combined, {Map{
        {"to", lottery_},
        {"gas", uint256_t(90000)},
        {"data", Tie(look, builder)},
    }, "latest"});
}

void Cashier::Land(Json::Value data) {
    const auto id(data["id"]);
    if (id.isNull()) {
        const auto method(data["method"].asString());
        orc_assert(method == "eth_subscription");

        const auto params(data["params"]);
        const auto result(params["result"]);
        const auto topics(result["topics"]);
        const Number<uint256_t> event(topics[0].asString());

        if (false) {
        } else if (event == Update_) {
#if 0
            const uint128_t subscription(params["subscription"].asString());

            const auto pot([&]() {
                const auto cache(cache_());
                const auto identity(cache->subscriptions_.find(subscription));
                orc_assert(identity != cache->subscriptions_.end());
                const auto pot(cache->pots_.find(identity->second));
                orc_assert(pot != cache->pots_.end());
                return pot->second;
            }());
#else
            const Number<uint256_t> funder(topics[1].asString());
            const Number<uint256_t> signer(topics[2].asString());
            const Identity identity{signer.num<uint256_t>(), funder.num<uint256_t>()};

            const auto pot([&]() {
                const auto cache(cache_());
                const auto pot(cache->pots_.find(identity));
                orc_assert(pot != cache->pots_.end());
                return pot->second;
            }());
#endif

            const auto data(Bless(result["data"].asString()));
            Window window(data);
            const auto [amount, escrow, unlock] = Coded<std::tuple<uint128_t, uint128_t, uint256_t>>::Decode(window);
            window.Stop();

            {
                const auto locked(pot->locked_());
                locked->amount_ = amount;
                locked->escrow_ = escrow;
                locked->unlock_ = unlock;
            }

            pot->set();
        } else if (event == Bound_) {
            std::cout << "BIND " << data << std::endl;
        } else orc_throw("unknown message " << data);
    } else {
        const auto value(id.asString());
        const auto [identity] = Take<Identity>(Bless(value.substr(1)));
        const auto result(Bless(data["result"].asString()));
        switch (value[0]) {
            case 'S': {
                orc_assert(cache_()->subscriptions_.emplace(result.num<uint128_t>(), identity).second);
            } break;

            case 'C': {
                Window window(result);
                const auto [amount, escrow, unlock, verify, codehash, shared] = Coded<std::tuple<uint128_t, uint128_t, uint256_t, Address, Bytes32, Bytes>>::Decode(window);
                window.Stop();

                const auto pot([this, &identity = identity]() {
                    const auto cache(cache_());
                    const auto pot(cache->pots_.find(identity));
                    orc_assert(pot != cache->pots_.end());
                    return pot->second;
                }());

                {
                    const auto locked(pot->locked_());
                    locked->amount_ = amount;
                    locked->escrow_ = escrow;
                    locked->unlock_ = unlock;
                }

                pot->set();
            } break;

            default:
                orc_assert(false);
        }
    }
}

void Cashier::Stop(const std::string &error) {
}

Cashier::Cashier(Endpoint endpoint, Locator locator, const Float &price, std::string currency, const Address &personal, std::string password, const Address &lottery, const uint256_t &chain, const Address &recipient) :
    endpoint_(std::move(endpoint)),
    locator_(std::move(locator)),

    price_(price),
    currency_(std::move(currency)),

    personal_(personal),
    password_(std::move(password)),

    lottery_(lottery),
    chain_(chain),
    recipient_(recipient)
{
    cppcoro::async_manual_reset_event ready;

    Spawn([&ready, this, &locator]() -> task<void> {
        auto duplex(std::make_unique<Duplex>());
        co_await duplex->Open(locator);

        auto station(std::make_unique<Sink<Station, Drain<Json::Value>>>(this));
        const auto structured(station->Wire<Sink<Structured>>());
        const auto inverted(structured->Wire<Inverted>(std::move(duplex)));
        inverted->Open();
        station_ = std::move(station);

        co_await Update();
        ready.set();

        for (;;) {
            co_await Sleep(5 * 60);
            co_await Update();
        }
    });

    Wait([&]() -> task<void> {
        co_await ready;
    }());
}

Float Cashier::Bill(size_t size) const {
    return price_ * size;
}

checked_int256_t Cashier::Convert(const Float &balance) const {
    const auto oxt(prices_()->oxt_);
    return checked_int256_t(balance / oxt * Two128);
}

Float Cashier::Credit(const uint256_t &now, const uint256_t &start, const uint256_t &until, const uint256_t &amount, const uint256_t &gas) const {
    const auto oxt(prices_()->oxt_);
    return Float(amount) * oxt / Two128;
}

task<void> Cashier::Check(const Address &signer, const Address &funder, const uint128_t &amount, const Address &recipient, const Buffer &receipt) {
    const auto [pot, subscribe] = [&]() -> std::tuple<S<Pot>, bool> {
        const auto cache(cache_());
        auto &pot(cache->pots_[{signer, funder}]);
        if (pot != nullptr)
            return {pot, false};
        else {
            pot = Make<Pot>();
            return {pot, true};
        }
    }();

    if (subscribe) {
        auto combined(Combine(signer, funder));

        co_await station_->Send("eth_subscribe", 'S' + combined, {"logs", Map{
            {"address", lottery_},
            {"topics", {{Update_, Bound_}, Number<uint256_t>(funder), Number<uint256_t>(signer)}},
        }});

        co_await Look(signer, funder, combined);
    }

    co_await *pot;

    const auto locked(pot->locked_());
    orc_assert(amount < locked->amount_);
    orc_assert(amount < locked->escrow_ / 2);
    orc_assert(locked->unlock_ == 0);
}

}
