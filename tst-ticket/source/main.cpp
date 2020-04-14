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


#include "endpoint.hpp"
#include "local.hpp"
#include "task.hpp"
#include "ticket.hpp"

namespace orc {

static const auto Update_(Hash("Update(address,address,uint128,uint128,uint256)"));
static const auto Bound_(Hash("Update(address,address)"));

// NOLINTNEXTLINE (modernize-avoid-c-arrays)
int Main(int argc, const char *const argv[]) {
    orc_assert(argc == 2);
    const uint256_t hash(argv[1]);

    return Wait([&]() -> task<int> {
        co_await Schedule();

        const Address lottery("0xb02396f06cc894834b7934ecf8c8e5ab5c1d12f1");
        const uint256_t chain(1);

        const auto local(Break<Local>());
        Endpoint endpoint(local, {"https", "cloudflare-eth.com", "443", "/"});
        const auto txn(co_await endpoint("eth_getTransactionByHash", {hash}));
        orc_assert(Address(txn["to"].asString()) == lottery);
        const uint256_t number(txn["blockNumber"].asString());
        std::cout << "number: " << std::dec << number << std::endl;
        const auto input(Bless(txn["input"].asString()));

        static Selector<void,
            Bytes32 /*reveal*/, Bytes32 /*commit*/,
            uint256_t /*issued*/, Bytes32 /*nonce*/,
            uint8_t /*v*/, Bytes32 /*r*/, Bytes32 /*s*/,
            uint128_t /*amount*/, uint128_t /*ratio*/,
            uint256_t /*start*/, uint128_t /*range*/,
            Address /*funder*/, Address /*recipient*/,
            Bytes /*receipt*/, std::vector<Bytes32> /*old*/
        > grab("grab");

        const auto block(co_await endpoint("eth_getBlockByHash", {txn["blockHash"].asString(), false}));
        const uint256_t timestamp(block["timestamp"].asString());
        std::cout << "timestamp: " << timestamp << std::endl;

        const auto [
            reveal, commit,
            issued, nonce,
            v, r, s,
            amount, ratio,
            start, range,
            funder, recipient,
            receipt, old
        ] = grab.Decode(input);

        std::cout << "start: " << start << std::endl;
        std::cout << "range: " << range << std::endl;

        const auto winner(Hash(Tie(reveal, issued, nonce)).skip<16>().num<uint128_t>() <= ratio);
        std::cout << "winner: " << winner << std::endl;

        std::cout << "amount: " << amount << std::endl;
        std::cout << "recipient: " << recipient << std::endl;
        std::cout << "funder: " << funder << std::endl;

        static const Selector<std::tuple<uint128_t, uint128_t, uint256_t, Address, Bytes32, Bytes>, Address, Address> look("look");

        using Ticket = Coder<Bytes32, Bytes32, uint256_t, Bytes32, Address, uint256_t, uint128_t, uint128_t, uint256_t, uint128_t, Address, Address, Bytes>;
        static const auto orchid(Hash("Orchid.grab"));
        const auto ticket(Hash(Ticket::Encode(orchid, commit, issued, nonce, lottery, chain, amount, ratio, start, range, funder, recipient, receipt)));
        const Address signer(Recover(Hash(Tie(Strung<std::string>("\x19""Ethereum Signed Message:\n32"), ticket)), v, r, s));
        std::cout << "signer: " << signer << std::endl;

        const std::string latest("latest");
        const auto [balance, escrow, unlock, verify, codehash, shared] = co_await look.Call(endpoint, latest, lottery, uint256_t(90000), funder, signer);
        std::cout << "balance: " << balance << std::endl;
        std::cout << "escrow: " << escrow << std::endl;
        std::cout << "unlock: " << unlock << std::endl;
        std::cout << "verify: " << verify << std::endl;
        std::cout << "codehash: " << codehash << std::endl;
        std::cout << "shared: " << shared << std::endl;

        const auto logs(co_await endpoint("eth_getLogs", {Map{
            {"fromBlock", "0x0"},
            {"toBlock", latest},
            {"address", lottery},
            {"topics", {{Update_, Bound_}, Number<uint256_t>(funder), Number<uint256_t>(signer)}},
        }}));

        for (const auto log : logs) {
            const uint256_t number(log["blockNumber"].asString());
            const uint256_t hash(log["transactionHash"].asString());
            const auto data(Bless(log["data"].asString()));
            const auto [balance, escrow, unlock] = Take<uint256_t, uint256_t, uint256_t>(data);
            std::cout << std::dec << number << " " << balance << " " << escrow << " " << unlock << std::endl;
        }

        co_return 0;
    }());
}

}

int main(int argc, const char *const argv[]) { try {
    return orc::Main(argc, argv);
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    return 1;
} }
