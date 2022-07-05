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


#ifndef ORCHID_TREZOR_HPP
#define ORCHID_TREZOR_HPP

#include "executor.hpp"

namespace orc {

class TrezorSession :
    public Valve
{
  private:
    const S<Base> base_;
    const std::string session_;

  public:
    TrezorSession(S<Base> base, std::string session);
    static task<S<TrezorSession>> New(S<Base> base);

    task<void> Open();
    task<void> Shut() noexcept override;

    template <uint16_t Type_, typename Response_, typename Request_>
    task<Response_> Call(uint16_t type, const Request_ &request) const;
};

class TrezorExecutor :
    public BasicExecutor
{
  private:
    const S<TrezorSession> session_;
    const std::vector<uint32_t> indices_;
    const Address address_;

  public:
    TrezorExecutor(S<TrezorSession> session, std::vector<uint32_t> indices, Address address);

    static task<S<TrezorExecutor>> New(S<TrezorSession> session, std::vector<uint32_t> indices);

    operator Address() const override;
    task<Signature> operator ()(const Chain &chain, const Buffer &data) const override;

    task<Bytes32> Send(const Chain &chain, const uint256_t &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data, bool eip155) const override;

    using BasicExecutor::Send;
};

}

#endif//ORCHID_TREZOR_HPP
