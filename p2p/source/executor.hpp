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


#ifndef ORCHID_EXECUTOR_HPP
#define ORCHID_EXECUTOR_HPP

#include "chain.hpp"

namespace orc {

struct Execution {
    std::optional<uint256_t> nonce;
    std::optional<uint256_t> bid;
    std::optional<uint64_t> gas;
};

class Executor {
  public:
    virtual ~Executor() = default;

    virtual operator Address() const = 0;
    virtual task<Signature> operator ()(const Chain &chain, const Buffer &data) const = 0;

    virtual task<Bytes32> Send(const Chain &chain, const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const = 0;

    task<Bytes32> Send(const Chain &chain, Execution execution, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const;
};

class MissingExecutor :
    public Executor
{
  public:
    operator Address() const override;
    task<Signature> operator ()(const Chain &chain, const Buffer &data) const override;

    task<Bytes32> Send(const Chain &chain, const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const override;

    using Executor::Send;
};

class UnlockedExecutor :
    public Executor
{
  private:
    const Address address_;

  public:
    UnlockedExecutor(Address address);

    operator Address() const override;
    task<Signature> operator ()(const Chain &chain, const Buffer &data) const override;

    task<Bytes32> Send(const Chain &chain, const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const override;

    using Executor::Send;
};

class PasswordExecutor :
    public Executor
{
  private:
    const Address address_;
    const std::string password_;

  public:
    PasswordExecutor(Address address, std::string password);

    operator Address() const override;
    task<Signature> operator ()(const Chain &chain, const Buffer &data) const override;

    task<Bytes32> Send(const Chain &chain, const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const override;

    using Executor::Send;
};

class BasicExecutor :
    public Executor
{
  public:
    task<Bytes32> Send(const Chain &chain, const Buffer &data) const;
    virtual task<Bytes32> Send(const Chain &chain, const uint256_t &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data, bool eip155) const = 0;
    task<Bytes32> Send(const Chain &chain, const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const override;

    using Executor::Send;
};

class SecretExecutor :
    public BasicExecutor
{
  private:
    const Secret secret_;

  public:
    SecretExecutor(const Secret &secret);

    operator Address() const override;
    task<Signature> operator ()(const Chain &chain, const Buffer &data) const override;

    task<Bytes32> Send(const Chain &chain, const uint256_t &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data, bool eip155) const override;

    using BasicExecutor::Send;
};

}

#endif//ORCHID_EXECUTOR_HPP
