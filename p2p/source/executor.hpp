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


#ifndef ORCHID_EXECUTOR_HPP
#define ORCHID_EXECUTOR_HPP

#include "endpoint.hpp"

namespace orc {

class Executor {
  protected:
    Endpoint &endpoint_;

  public:
    Executor(Endpoint &endpoint);

    virtual ~Executor() = default;

    virtual operator Address() const = 0;
    virtual task<Signature> operator ()(const Buffer &data) const = 0;

    virtual task<Bytes32> Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const = 0;

    task<Bytes32> Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const;
    task<Bytes32> Send(const std::optional<Address> &target, const uint256_t &value, const Buffer &data = Bytes()) const;
};

class MissingExecutor :
    public Executor
{
  public:
    using Executor::Executor;

    operator Address() const override;
    task<Signature> operator ()(const Buffer &data) const override;

    task<Bytes32> Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const override;

    using Executor::Send;
};

class UnlockedExecutor :
    public Executor
{
  private:
    Address common_;

  public:
    UnlockedExecutor(Endpoint &endpoint, Address common);

    operator Address() const override;
    task<Signature> operator ()(const Buffer &data) const override;

    task<Bytes32> Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const override;

    using Executor::Send;
};

class PasswordExecutor :
    public Executor
{
  private:
    Address common_;
    std::string password_;

  public:
    PasswordExecutor(Endpoint &endpoint, Address common, std::string password);

    operator Address() const override;
    task<Signature> operator ()(const Buffer &data) const override;

    task<Bytes32> Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const override;

    using Executor::Send;
};

class SecretExecutor :
    public Executor
{
  private:
    Secret secret_;

  public:
    SecretExecutor(Endpoint &endpoint, const Secret &secret);

    operator Address() const override;
    task<Signature> operator ()(const Buffer &data) const override;

    task<Bytes32> Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const override;
    task<Bytes32> Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data, const std::optional<uint256_t> &chain) const;

    using Executor::Send;
};

}

#endif//ORCHID_EXECUTOR_HPP
