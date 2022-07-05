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


#include "messages.pb.h"
#include "messages-common.pb.h"
#include "messages-ethereum.pb.h"

#include "nested.hpp"
#include "trezor.hpp"

namespace orc {

namespace tzr = hw::trezor::messages;
#define ORC_TREZOR(type) Call<tzr::MessageType_##type, tzr::ethereum::type>

static task<std::string> Trezor(const S<Base> &base, const std::string &path, const std::string &data = {}) {
    co_return (co_await base->Fetch("POST", {{"http", "localhost", "21325"}, path}, {
        {"origin", "https://connect.trezor.io"},
    }, data)).ok();
}

TrezorSession::TrezorSession(S<Base> base, std::string session) :
    Valve(typeid(*this).name()),
    base_(std::move(base)),
    session_(std::move(session))
{
}

task<S<TrezorSession>> TrezorSession::New(S<Base> base) {
    const auto devices(Parse(co_await Trezor(base, "/enumerate")));
    const auto device(devices.at(0).as_object());
    const auto previous(device.find("session"));
    const auto session(Parse(co_await Trezor(base, "/acquire/" + Str(device.at("path")) + "/" + (previous == device.end() || previous->value().is_null() ? "null" : Str(previous->value())))).as_object());
    co_return Break<TrezorSession>(std::move(base), Str(session.at("session")));
}

task<void> TrezorSession::Shut() noexcept {
    co_await Trezor(base_, "/release/" + session_);
    co_await Valve::Shut();
}

template <uint16_t Type_, typename Response_, typename Request_>
task<Response_> TrezorSession::Call(uint16_t type, const Request_ &request) const {
    std::string data;
    orc_assert(request.SerializeToString(&data));
    orc_assert(!data.empty());

  retry:
    data = co_await Trezor(base_, "/call/" + session_, Tie(type, uint32_t(data.size()), data).hex(false));
    const auto [kind, size, rest] = Take<uint16_t, uint32_t, Rest>(Bless(data));
    orc_assert(size == rest.size());

    #define ORC_RESPONSE(type) \
        type response; \
        orc_assert(response.ParseFromArray(rest.data(), Fit(rest.size())));

    switch (kind) {
        case tzr::MessageType_Failure: {
            ORC_RESPONSE(tzr::common::Failure);
            orc_throw(response.message());
        } break;

        case tzr::MessageType_PinMatrixRequest: {
            ORC_RESPONSE(tzr::common::PinMatrixRequest);
            tzr::common::PinMatrixAck request;
            std::cout << "pin: " << std::flush;
            std::string pin;
            std::getline(std::cin, pin);
            request.set_pin(pin);
            orc_assert(request.SerializeToString(&data));
            type = tzr::MessageType_PinMatrixAck;
            goto retry;
        } break;

        case tzr::MessageType_ButtonRequest: {
            ORC_RESPONSE(tzr::common::ButtonRequest);
            tzr::common::ButtonAck request;
            orc_assert(request.SerializeToString(&data));
            type = tzr::MessageType_ButtonAck;
            goto retry;
        } break;

        case tzr::MessageType_PassphraseRequest: {
            ORC_RESPONSE(tzr::common::PassphraseRequest);
            tzr::common::PassphraseAck request;
            std::cout << "passphrase: " << std::flush;
            std::string passphrase;
            std::getline(std::cin, passphrase);
            request.set_passphrase(passphrase);
            orc_assert(request.SerializeToString(&data));
            type = tzr::MessageType_PassphraseAck;
            goto retry;
        } break;

        default: {
            orc_assert_(kind == Type_, "incorrect kind " << kind);
            ORC_RESPONSE(Response_);
            co_return std::move(response);
        } break;
    }
}

template <typename Request_>
static void Trezor(Request_ &request, const std::vector<uint32_t> &indices) {
    for (const auto &index : indices)
        request.add_address_n(index);
}

TrezorExecutor::TrezorExecutor(S<TrezorSession> session, std::vector<uint32_t> indices, Address address) :
    session_(std::move(session)),
    indices_(std::move(indices)),
    address_(std::move(address))
{
}

task<S<TrezorExecutor>> TrezorExecutor::New(S<TrezorSession> session, std::vector<uint32_t> indices) {
    tzr::ethereum::EthereumGetAddress request;
    Trezor(request, indices);
    const auto response(co_await session->ORC_TREZOR(EthereumAddress)(tzr::MessageType_EthereumGetAddress, request));
    co_return Make<TrezorExecutor>(std::move(session), std::move(indices), response.address());
}

TrezorExecutor::operator Address() const {
    return address_;
}

task<Signature> TrezorExecutor::operator ()(const Chain &chain, const Buffer &data) const {
    tzr::ethereum::EthereumSignMessage request;
    Trezor(request, indices_);
    request.set_message(data.str());
    const auto response(co_await session_->ORC_TREZOR(EthereumMessageSignature)(tzr::MessageType_EthereumSignMessage, request));
    Log() << Subset(response.signature()) << std::endl;
    orc_insist(false);
}

task<Bytes32> TrezorExecutor::Send(const Chain &chain, const uint256_t &nonce, const uint256_t &bid, const uint64_t &gas, const std::optional<Address> &target, const uint256_t &value, const Buffer &data, bool eip155) const {
    tzr::ethereum::EthereumSignTx request;
    Trezor(request, indices_);
    request.set_nonce(Stripped(nonce));
    request.set_gas_price(Stripped(bid));
    request.set_gas_limit(Stripped(gas));
    if (target)
        request.set_to(target->str());
    request.set_value(Stripped(value));
    if (eip155)
        request.set_chain_id(uint32_t(chain.operator const uint256_t &()));

    Window window(data);
    auto size(window.size());
    request.set_data_length(Fit(size));
    if (size > 1024) size = 1024;

    request.set_data_initial_chunk(window.Take(size).str());
    auto response(co_await session_->ORC_TREZOR(EthereumTxRequest)(tzr::MessageType_EthereumSignTx, request));
    while (response.has_data_length()) {
        tzr::ethereum::EthereumTxAck request;
        request.set_data_chunk(window.Take(response.data_length()).str());
        response = co_await session_->ORC_TREZOR(EthereumTxRequest)(tzr::MessageType_EthereumTxAck, request);
    }

    orc_assert(window.done());

    const uint256_t v(response.signature_v());
    orc_assert(Record(nonce, bid, gas, target, value, Beam(data), chain, v, Number<uint256_t>(Subset(response.signature_r())).num<uint256_t>(), Number<uint256_t>(Subset(response.signature_s())).num<uint256_t>()).from_ == address_);
    co_return co_await BasicExecutor::Send(chain, Subset(Implode({nonce, bid, gas, target, value, data, v, response.signature_r(), response.signature_s()})));
}

}
