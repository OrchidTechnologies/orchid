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


#include "executor.hpp"
#include "nested.hpp"

namespace orc {

Executor::Executor(Endpoint &endpoint) :
    endpoint_(endpoint)
{
}

task<Bytes32> Executor::Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    co_return co_await Send(nonce, bid, To((co_await endpoint_("eth_estimateGas", {Multi{
        {"from", operator Address()},
        {"gasPrice", bid},
        {"to", target},
        {"value", value},
        {"data", data},
    }})).asString()), target, value, data);
}

task<Bytes32> Executor::Send(const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    co_return co_await Send(std::nullopt, co_await endpoint_.Bid(), target, value, data);
}


MissingExecutor::operator Address() const {
    orc_assert(false);
}

task<Signature> MissingExecutor::operator ()(const Buffer &data) const {
    orc_assert(false);
}

task<Bytes32> MissingExecutor::Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    orc_assert(false);
}


UnlockedExecutor::UnlockedExecutor(Endpoint &endpoint, Address common) :
    Executor(endpoint),
    common_(std::move(common))
{
}

UnlockedExecutor::operator Address() const {
    return common_;
}

task<Signature> UnlockedExecutor::operator ()(const Buffer &data) const {
    co_return Signature(Bless((co_await endpoint_("eth_sign", {common_, data})).asString()));
}

task<Bytes32> UnlockedExecutor::Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    co_return co_await endpoint_.Send("eth_sendTransaction", {Multi{
        {"from", common_},
        {"nonce", nonce},
        {"gasPrice", bid},
        {"gas", gas},
        {"to", target},
        {"value", value},
        {"data", data},
    }});
}


PasswordExecutor::PasswordExecutor(Endpoint &endpoint, Address common, std::string password) :
    Executor(endpoint),
    common_(std::move(common)),
    password_(std::move(password))
{
}

PasswordExecutor::operator Address() const {
    return common_;
}

task<Signature> PasswordExecutor::operator ()(const Buffer &data) const {
    co_return Signature(Bless((co_await endpoint_("personal_sign", {common_, data, password_})).asString()));
}

task<Bytes32> PasswordExecutor::Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    co_return co_await endpoint_.Send("personal_sendTransaction", {Multi{
        {"from", common_},
        {"nonce", nonce},
        {"gasPrice", bid},
        {"gas", gas},
        {"to", target},
        {"value", value},
        {"data", data},
    }, password_});
}


SecretExecutor::SecretExecutor(Endpoint &endpoint, const Secret &secret) :
    Executor(endpoint),
    secret_(secret)
{
}

SecretExecutor::operator Address() const {
    return Commonize(secret_);
}

task<Signature> SecretExecutor::operator ()(const Buffer &data) const {
    co_return Sign(secret_, Hash(Tie("\x19""Ethereum Signed Message:\n", std::to_string(data.size()), data)));
}

task<Bytes32> SecretExecutor::Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    co_return co_await Send(nonce, bid, gas, target, value, data, co_await endpoint_.Chain());
}

task<Bytes32> SecretExecutor::Send(const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data, const std::optional<uint256_t> &chain) const {
    const auto address(operator Address());
    const uint256_t count(nonce ? *nonce : uint256_t((co_await endpoint_("eth_getTransactionCount", {address, "latest"})).asString()));
    co_return co_await endpoint_.Send("eth_sendRawTransaction", {Subset([&]() { if (chain) {
        const auto signature(Sign(secret_, Hash(Implode({count, bid, gas, target, value, data, *chain, uint256_t(0), uint256_t(0)}))));
        return Implode({count, bid, gas, target, value, data, signature.v_ + 35 + 2 * *chain, signature.r_, signature.s_});
    } else {
        const auto signature(Sign(secret_, Hash(Implode({count, bid, gas, target, value, data}))));
        return Implode({count, bid, gas, target, value, data, uint8_t(signature.v_ + 27), signature.r_, signature.s_});
    } }())});
}

}
