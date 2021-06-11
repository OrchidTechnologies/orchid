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


#include "chain.hpp"
#include "local.hpp"
#include "task.hpp"
#include "ticket.hpp"

namespace orc {

static const auto Update_(HashK("Update(address,address,uint128,uint128,uint256)"));
static const auto Bound_(HashK("Update(address,address)"));

task<Beam> Search(const S<Chain> &chain, const Address &contract, const Brick<32> &hash) {
    //co_return Bless("0x66458bbdd330f03b5966c622edcaa802932935fae4276ff7914479676be56e52773a54da68139e95b80dd8dc0aee4d37e2a9df058f29decc631d6ac6c8b34fc6414f7e91000000000000000000000000000000000000000000000000000000005eeb83d727e30c91220a33fe20d4561e53a2e65611ca002512efa3d9569f929d619263fe000000000000000000000000000000000000000000000000000000000000001b954b3725829049af21c58931aa3236827041c0814f7bcb4c8e4d6eea9d371de17d117839e5f2f45002d21eccfc8be1a58f31e0594385a93b280a85cac55d403500000000000000000000000000000000000000000000000068155a43676e000000000000000000000000000000000000ffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000005eeb9ff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000091f053f14a814a8229f6473fcbb6f8bc42f43da50000000000000000000000005b2a0ecd5560237ac8418d931a789fcd9fffdc1900000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");

    const auto txn(co_await (*chain)("eth_getTransactionByHash", {hash}));
    orc_assert(!txn.isNull());
    std::cerr << txn << std::endl;
    orc_assert(Address(txn["to"].asString()) == contract);

    const uint256_t number(txn["blockNumber"].asString());
    std::cout << "number: " << std::dec << number << std::endl;

    const auto block(co_await (*chain)("eth_getBlockByHash", {txn["blockHash"].asString(), false}));
    const uint256_t timestamp(block["timestamp"].asString());
    std::cout << "timestamp: " << timestamp << std::endl;

    co_return Bless(txn["input"].asString());
}

task<void> Decode0(const Brick<32> &hash) {
    const Address contract("0xb02396f06cc894834b7934ecf8c8e5ab5c1d12f1");

    const S<Base> base(Break<Local>());
    const auto chain(co_await Chain::New(Endpoint({{"https", "cloudflare-eth.com", "443"}, "/"}, base), {}));

    const auto input(co_await Search(chain, contract, hash));

    static Selector<void,
        Bytes32 /*reveal*/, Bytes32 /*commit*/,
        uint256_t /*issued*/, Bytes32 /*nonce*/,
        uint8_t /*v*/, Bytes32 /*r*/, Bytes32 /*s*/,
        uint128_t /*amount*/, uint128_t /*ratio*/,
        uint256_t /*start*/, uint128_t /*range*/,
        Address /*funder*/, Address /*recipient*/,
        Bytes /*receipt*/, std::vector<Bytes32> /*old*/
    > grab("grab");

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

    const auto winner(HashK(Tie(reveal, issued, nonce)).skip<16>().num<uint128_t>() <= ratio);
    std::cout << "winner: " << winner << std::endl;

    std::cout << "amount: " << amount << std::endl;
    std::cout << "recipient: " << recipient << std::endl;
    std::cout << "funder: " << funder << std::endl;

    static const Selector<std::tuple<uint128_t, uint128_t, uint256_t, Address, Bytes32, Bytes>, Address, Address> look("look");

    const Ticket0 ticket{commit, issued, nonce, amount, ratio, start, range, funder, recipient};
    const auto digest(ticket.Encode(contract, *chain, receipt));
    const Address signer(Recover(HashK(Tie("\x19""Ethereum Signed Message:\n32", digest)), v, r, s));
    std::cout << "signer: " << signer << std::endl;

    const std::string latest("latest");
    const auto [balance, escrow, unlock, verify, codehash, shared] = co_await look.Call(*chain, latest, contract, uint256_t(90000), funder, signer);
    std::cout << "balance: " << balance << std::endl;
    std::cout << "escrow: " << escrow << std::endl;
    std::cout << "unlock: " << unlock << std::endl;
    std::cout << "verify: " << verify << std::endl;
    std::cout << "codehash: " << codehash << std::endl;
    std::cout << "shared: " << shared << std::endl;

#if 0
    const auto logs(co_await (*chain)("eth_getLogs", {Multi{
        {"fromBlock", "0x0"},
        {"toBlock", latest},
        {"address", contract},
        {"topics", {{Update_, Bound_}, Number<uint256_t>(funder.num()), Number<uint256_t>(signer.num())}},
    }}));

    for (const auto log : logs) {
        const uint256_t number(log["blockNumber"].asString());
        const uint256_t hash(log["transactionHash"].asString());
        const auto data(Bless(log["data"].asString()));
        const auto [balance, escrow, unlock] = Take<uint256_t, uint256_t, uint256_t>(data);
        std::cout << std::dec << number << " " << balance << " " << escrow << " " << unlock << std::endl;
    }
#endif
}

task<void> Decode1(const Brick<32> &hash) {
    const Address contract("0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82");

    const S<Base> base(Break<Local>());
    const auto chain(co_await Chain::New(Endpoint({{"https", "rpc.xdaichain.com", "443"}, "/"}, base), {}));

    const auto input(co_await Search(chain, contract, hash));

    static Selector<void,
        Address /*token*/,
        Address /*recipient*/,
        std::vector<Payment1> /*payments*/,
        std::vector<Bytes32> /*refunds*/
    > claim("claim");

    const auto [token, recipient, payments, refunds] = claim.Decode(input);

    for (const auto &payment : payments) {
        //return Payment1(data_, reveal, uint256_t(issued_) << 192 | uint256_t(nonce_.num<uint64_t>()) << 128 | amount_, uint256_t(expire_) << 225 | uint256_t(ratio_) << 161 | uint256_t(funder_.num()) << 1 | signature.v_, signature.r_, signature.s_);

        /*struct Ticket {
            uint256 data;
            uint256 reveal;

            uint64 issued;
            uint64 nonce;
            uint128 amount;

            uint31 expire;
            uint64 ratio;
            address funder;
            uint1 v;

            bytes32 r;
            bytes32 s;
        }*/

        const auto &data(std::get<0>(payment));
        const auto &reveal(std::get<1>(payment));
        const uint64_t issued(std::get<2>(payment) >> 192);
        const Number<uint64_t> nonce(uint64_t(std::get<2>(payment) >> 128));
        const uint128_t amount(std::get<2>(payment) >> 0);
        const uint32_t expire(std::get<3>(payment) >> 225);
        const uint64_t ratio(std::get<3>(payment) >> 161);
        const Address funder(uint160_t(std::get<3>(payment) >> 1));
        const uint8_t v(std::get<3>(payment) & 1);
        const auto &r(std::get<4>(payment));
        const auto &s(std::get<5>(payment));

        std::cout << "data: " << data << std::endl;
        std::cout << "expire: " << expire << std::endl;

        const auto winner(HashK(Tie(reveal, issued, nonce)).skip<24>().num<uint64_t>() <= ratio);
        std::cout << "winner: " << winner << std::endl;

        std::cout << "amount: " << amount << std::endl;
        std::cout << "recipient: " << recipient << std::endl;
        std::cout << "funder: " << funder << std::endl;

        static Selector<std::tuple<uint256_t, uint256_t>, Address, Address, Address> read("read");

        const Ticket1 ticket{recipient, HashK(reveal), issued, nonce, amount, expire, ratio, funder, data};
        const auto digest(ticket.Encode(contract, *chain, {}));
        const Signature signature(r, s, v);
        const Address signer(Recover(digest, signature));
        std::cout << "signer: " << signer << std::endl;

        const std::string latest("latest");
        const auto [escrow_balance, unlock_warned] = co_await read.Call(*chain, "latest", contract, 90000, token, funder, signer);
        std::cout << "balance: " << uint128_t(escrow_balance) << std::endl;
        std::cout << "escrow: " << (escrow_balance >> 128) << std::endl;
        std::cout << "unlock: " << uint128_t(unlock_warned) << std::endl;
        std::cout << "warned: " << uint64_t(unlock_warned >> 128) << std::endl;
        std::cout << "marked: " << uint64_t(unlock_warned >> 192) << std::endl;
    }
}

int Main(int argc, const char *const argv[]) {
    orc_assert(argc == 2);
    const Brick<32> hash(Bless(argv[1]));

    return Wait([&]() -> task<int> {
        co_await Schedule();
        //co_await Decode0(hash);
        co_await Decode1(hash);
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
