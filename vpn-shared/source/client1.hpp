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


#ifndef ORCHID_CLIENT1_HPP
#define ORCHID_CLIENT1_HPP

#include "client.hpp"
#include "crypto.hpp"
#include "float.hpp"
#include "jsonrpc.hpp"
#include "locked.hpp"
#include "ticket.hpp"
#include "token.hpp"
#include "updated.hpp"

namespace orc {

class Client1 :
    public Client
{
  private:
    const Market market_;
    const Address lottery_;
    const Secret secret_;
    const Address funder_;
    const Bytes hoarded_;
    const uint128_t face_;

    struct Locked_ {
        int64_t serial_ = -1;
        Bytes32 commit_ = Zero<32>();
        Address recipient_ = 0;
    }; Locked<Locked_> locked_;

    task<void> Submit(const Float &amount) override;
    void Invoice(const Bytes32 &id, const Buffer &data) override;

  public:
    Client1(BufferDrain &drain, S<Updated<Prices>> oracle, Market market, const Address &lottery, const Secret &secret, const Address &funder, const uint128_t &face);

    // XXX: this should be task<Client &> but my task Transfer doesn't support that
    static task<Client1 *> Wire(BufferSunk &sunk, S<Updated<Prices>> oracle, Market market, const Address &lottery, const Secret &secret, const Address &funder);

    uint128_t Face();
    uint64_t Gas();

    Address Recipient() override;
};

}

#endif//ORCHID_CLIENT1_HPP
