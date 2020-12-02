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


#include "baton.hpp"
#include "duplex.hpp"
#include "json.hpp"
#include "lottery1.hpp"
#include "parallel.hpp"
#include "sleep.hpp"
#include "structured.hpp"
#include "updater.hpp"

namespace orc {

#if 0
static const auto Update_(Hash("Update(address,address,uint128,uint128,uint256)"));
static const auto Bound_(Hash("Update(address,address)"));

task<void> Lottery1::Look(const Address &signer, const Address &funder, const std::string &combined) {
    static const auto look(Hash("look(address,address)").Clip<4>().num<uint32_t>());
    Builder builder;
    Coder<Address, Address>::Encode(builder, funder, signer);
    co_await station_->Send("eth_call", 'C' + combined, {Multi{
        {"to", contract_},
        {"gas", uint64_t(90000)},
        {"data", Tie(look, builder)},
    }, "latest"});
}

void Lottery1::Land(Json::Value data) { try {
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

            (*pot)();
        } else if (event == Bound_) {
            std::cout << "BIND " << data << std::endl;
        } else orc_throw("unknown message " << data);
    } else {
        const auto value(id.asString());
        const auto [identity] = Take<Identity>(Bless(value.substr(1)));
        const auto result(data["result"].asString());
        switch (value[0]) {
            case 'S': {
                orc_assert(cache_()->subscriptions_.emplace(result, identity).second);
            } break;

            case 'C': {
                const auto data(Bless(result));
                Window window(data);
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

                (*pot)();
            } break;

            default:
                orc_insist(false);
        }
    }
} orc_stack({}, "parsing " << data) }

void Lottery1::Stop(const std::string &error) noexcept {
    orc_insist_(false, error);
    Valve::Stop();
}
#endif

Lottery1::Lottery1(Market market, Address contract) :
    Valve(typeid(*this).name()),

    market_(std::move(market)),
    contract_(std::move(contract))
{
}

#if 0
void Lottery1::Open(S<Origin> origin, Locator locator) {
    Wait([&]() -> task<void> {
        auto duplex(std::make_unique<Duplex>(origin));
        co_await duplex->Open(locator);

        auto station(std::make_unique<Covered<Sink<Station, Drain<Json::Value>>>>(*this));
        auto &structured(station->Wire<BufferSink<Structured>>());
        auto &inverted(structured.Wire<Inverted>(std::move(duplex)));
        inverted.Open();
        station_ = std::move(station);
    }());
}
#endif

task<void> Lottery1::Shut() noexcept {
    co_await Valve::Shut();
}

std::pair<Float, uint256_t> Lottery1::Credit(const uint256_t &now, const uint256_t &start, const uint128_t &range, const uint128_t &amount, const uint128_t &ratio, const uint64_t &gas) const {
    // XXX this used to use ethgasstation but now has a pretty lame gas model
    // XXX in fact I am not correctly modelling this problem at all anymore
    const auto bid((*market_.bid_)());
    return {(Float(amount) * market_.currency_.dollars_() - Float(gas * bid) * market_.currency_.dollars_()) * Float(ratio + 1) / Two128, bid};
}

task<bool> Lottery1::Check(const Address &signer, const Address &funder, const uint128_t &amount, const Address &recipient) {
    static Selector<std::tuple<uint256_t, uint256_t, uint256_t>, Address, Address, Address> read_("read");
    auto [escrow_balance, unlock_warned, bound] = co_await read_.Call(*market_.chain_, "latest", contract_, 90000, funder, signer, recipient);

    uint128_t escrow(escrow_balance >> 128);
    const uint128_t balance(escrow_balance);
    const uint128_t unlock(unlock_warned >> 128);
    const uint128_t warned(unlock_warned);

    if (unlock != 0) {
        orc_assert(escrow > warned);
        escrow -= warned;
    }

    if (amount > balance)
        co_return false;
    if (amount > escrow / 2)
        co_return false;
    co_return true;
}

}
