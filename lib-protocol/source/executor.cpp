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


#include "executor.hpp"
#include "nested.hpp"

namespace orc {

task<Bytes32> SimpleExecutor::Send(const Chain &chain, Execution execution, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const { orc_block({
    const auto bid(execution.bid ? *execution.bid : co_await chain.Bid());
    co_return co_await Send_(chain, execution.nonce, bid, execution.gas ? *execution.gas : To<uint64_t>((co_await chain("eth_estimateGas", {Multi{
        {"from", operator Address()},
        {"gasPrice", bid},
        {"to", target},
        {"value", value},
        {"data", data},
    }})).asString()), target, value, data);
}, "sending " << data << " with " << value << " to " << target); }


ManualExecutor::ManualExecutor(Address address) :
    address_(std::move(address))
{
}

ManualExecutor::operator Address() const {
    return address_;
}

task<Signature> ManualExecutor::operator ()(const Chain &chain, const Buffer &data) const {
    orc_assert(false);
}

task<Bytes32> ManualExecutor::Send_(const Chain &chain, const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    std::cout << "send " << (target ? *target : std::string("null")) << " " << value << " " << data << " --gas " << gas << std::endl;
    co_return Zero<32>();
}


UnlockedExecutor::UnlockedExecutor(Address address) :
    address_(std::move(address))
{
}

UnlockedExecutor::operator Address() const {
    return address_;
}

task<Signature> UnlockedExecutor::operator ()(const Chain &chain, const Buffer &data) const {
    co_return Signature(Bless((co_await chain("eth_sign", {address_, data})).asString()));
}

task<Bytes32> UnlockedExecutor::Send_(const Chain &chain, const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    co_return co_await chain.Send("eth_sendTransaction", {Multi{
        {"from", address_},
        {"nonce", nonce},
        {"gasPrice", bid},
        {"gas", gas},
        {"to", target},
        {"value", value},
        {"data", data},
    }});
}


PasswordExecutor::PasswordExecutor(Address address, std::string password) :
    address_(std::move(address)),
    password_(std::move(password))
{
}

PasswordExecutor::operator Address() const {
    return address_;
}

task<Signature> PasswordExecutor::operator ()(const Chain &chain, const Buffer &data) const {
    co_return Signature(Bless((co_await chain("personal_sign", {address_, data, password_})).asString()));
}

task<Bytes32> PasswordExecutor::Send_(const Chain &chain, const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    co_return co_await chain.Send("personal_sendTransaction", {Multi{
        {"from", address_},
        {"nonce", nonce},
        {"gasPrice", bid},
        {"gas", gas},
        {"to", target},
        {"value", value},
        {"data", data},
    }, password_});
}


task<Bytes32> BasicExecutor::Send(const Chain &chain, const Buffer &data) const {
    co_return co_await chain.Send("eth_sendRawTransaction", {data});
}

task<Bytes32> BasicExecutor::Send_(const Chain &chain, const std::optional<uint256_t> &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    const auto count(nonce ? *nonce : uint256_t((co_await chain("eth_getTransactionCount", {operator Address(), "latest"})).asString()));
    co_return co_await Send_(chain, count, bid, gas, target, value, data, true);
}


SecretExecutor::SecretExecutor(const Secret &secret) :
    secret_(secret)
{
}

SecretExecutor::operator Address() const {
    return Derive(secret_);
}

task<Signature> SecretExecutor::operator ()(const Chain &chain, const Buffer &data) const {
    co_return Sign(secret_, HashK(Tie("\x19""Ethereum Signed Message:\n", std::to_string(data.size()), data)));
}

task<Bytes32> SecretExecutor::Send_(const Chain &chain, const uint256_t &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data, bool eip155) const {
    co_return co_await BasicExecutor::Send(chain, Subset([&]() { if (eip155) {
        const auto signature(Sign(secret_, HashK(Implode({nonce, bid, gas, target, value, data, chain.operator const uint256_t &(), uint256_t(0), uint256_t(0)}))));
        return Implode({nonce, bid, gas, target, value, data, signature.v_ + 35 + 2 * chain.operator const uint256_t &(), signature.r_, signature.s_});
    } else {
        const auto signature(Sign(secret_, HashK(Implode({nonce, bid, gas, target, value, data}))));
        return Implode({nonce, bid, gas, target, value, data, uint8_t(signature.v_ + 27), signature.r_, signature.s_});
    } }()));
}

}
