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


#ifndef ORCHID_CASHIER_HPP
#define ORCHID_CASHIER_HPP

#include <map>
#include <string>

#include "endpoint.hpp"
#include "event.hpp"
#include "fiat.hpp"
#include "gauge.hpp"
#include "local.hpp"
#include "locked.hpp"
#include "locator.hpp"
#include "sleep.hpp"
#include "signed.hpp"
#include "spawn.hpp"
#include "station.hpp"
#include "updated.hpp"

namespace orc {

typedef std::tuple<Address, Address> Identity;

static std::string Combine(const Address &signer, const Address &funder) {
    return Tie(signer, funder).hex();
}

struct Pot :
    public Event
{
    struct Locked_ {
        uint128_t amount_ = 0;
        uint128_t escrow_ = 0;
        uint256_t unlock_ = 0;
    }; Locked<Locked_> locked_;
};

class Cashier :
    public Valve,
    public Drain<Json::Value>
{
  private:
    const Endpoint endpoint_;

    const Float price_;

    const Address personal_;
    const std::string password_;

    const Address lottery_;
    const uint256_t chain_;
    const Address recipient_;

    U<Station> station_;

    struct Cache_ {
        std::map<uint128_t, Identity> subscriptions_;
        std::map<Identity, S<Pot>> pots_;
    }; Locked<Cache_> cache_;

    task<void> Look(const Address &signer, const Address &funder, const std::string &combined);

  protected:
    void Land(Json::Value data) override;
    void Stop(const std::string &error) noexcept override;

  public:
    Cashier(Endpoint endpoint, const Float &price, const Address &personal, std::string password, const Address &lottery, const uint256_t &chain, const Address &recipient);
    ~Cashier() override = default;

    void Open(S<Origin> origin, Locator locator);
    task<void> Shut() noexcept override;

    auto Tuple() const {
        return std::tie(lottery_, chain_, recipient_);
    }

    Float Bill(size_t size) const;
    task<bool> Check(const Address &signer, const Address &funder, const uint128_t &amount, const Address &recipient, const Buffer &receipt);

    template <typename Selector_, typename... Args_>
    void Send(Selector_ &selector, const uint256_t &gas, const uint256_t &price, Args_ &&...args) {
        Spawn([=]() mutable noexcept -> task<void> {
            for (;;) {
                orc_ignore({
                    co_await selector.Send(endpoint_, personal_, password_, lottery_, gas, price, std::forward<Args_>(args)...);
                    break;
                });

                // XXX: I should dump these to a disk queue as they are worth "real money"
                // XXX: that same disk queue should maybe be in charge of the old tickets?
                co_await Sleep(5000);
            }
        }, __FUNCTION__);
    }
};

}

#endif//ORCHID_CASHIER_HPP
