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


#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include "endpoint.hpp"
#include "float.hpp"
#include "load.hpp"
#include "local.hpp"
#include "signed.hpp"
#include "sleep.hpp"
#include "ticket.hpp"

namespace orc {

namespace po = boost::program_options;

static const Float Two128(uint256_t(1) << 128);

bool Zeros(const Region &data) {
    return memchr(data.data(), '\0', data.size()) != nullptr;
}

template <size_t Size_>
Bytes32 Nonzero() {
    for (;;) {
        const auto value(Random<32>());
        if (!Zeros(value))
            return value;
    }
}

static const uint256_t maximum_(6721975);
static const uint256_t minimum_(100000);

struct Tester {
    Endpoint &endpoint_;
    uint256_t chain_;

    const Address deployer_;
    const Address customer_;
    const Address provider_;

    task<Receipt> Receipt(const Bytes32 &transaction) {
        for (;;) {
            if (auto maybe{co_await endpoint_(transaction)}) {
                auto &receipt(*maybe);
                co_return std::move(receipt);
            }
            co_await Sleep(1000);
        }
    }

    task<bool> Audit(const std::string &name, const Bytes32 &transaction) {
        const auto receipt(co_await Receipt(transaction));
        Log() << (receipt.status_ ? '+' : '-') << transaction << " " << name << ": " << std::dec << receipt.gas_ << std::endl;
        co_return receipt.status_;
    }

    task<void> Test0(const Address &token) {
        Log() << "==========" << std::endl;
        Log() << "lottery0" << std::endl;

        static Selector<bool, Address, uint256_t> approve("approve");

        static Selector<void, Address, Address, Bytes> bind("bind");
        static const Selector<std::tuple<uint128_t, uint128_t, uint256_t, Address, Bytes32, Bytes>, Address, Address> look("look");
        static Selector<void, Address, uint128_t, uint128_t> push("push");

        static Selector<void,
            Bytes32 /*reveal*/, Bytes32 /*commit*/,
            uint256_t /*issued*/, Bytes32 /*nonce*/,
            uint8_t /*v*/, Bytes32 /*r*/, Bytes32 /*s*/,
            uint128_t /*amount*/, uint128_t /*ratio*/,
            uint256_t /*start*/, uint128_t /*range*/,
            Address /*funder*/, Address /*recipient*/,
            Bytes /*receipt*/, std::vector<Bytes32> /*old*/
        > grab("grab");

      secret:
        const auto secret(Random<32>());
        const Address signer(Commonize(secret));
        if (Zeros(signer.buf()))
            goto secret;

        const auto lottery((co_await Receipt(co_await Constructor<Address>().Send(endpoint_, deployer_, maximum_, Bless(Load("../lot-ethereum/build/OrchidLottery0.bin")), token))).contract_);

        const auto show([&]() -> task<void> {
            const auto [balance, escrow, unlock, verify, codehash, shared] = co_await look.Call(endpoint_, "latest", lottery, 90000, customer_, signer);
            Log() << std::dec << balance << " " << escrow << " | " << unlock << std::endl;
        });

        //co_await Audit("bind", co_await endpoint_.Send(customer_, lottery, maximum_, bind(signer, lottery, {})));

        co_await Audit("approve", co_await endpoint_.Send(customer_, token, minimum_, approve(lottery, 10)));
        co_await Audit("push", co_await endpoint_.Send(customer_, lottery, maximum_, push(signer, 10, 4)));

        co_await show();

        const auto reveal(Nonzero<32>());
        const auto commit(Hash(reveal));

        const auto nonce(Nonzero<32>());

        const auto funder(customer_);
        const auto recipient(provider_);
        const Bytes receipt;

        const uint128_t face(2);
        const uint128_t ratio(Float(Two128) - 1);

        const auto issued(Timestamp());
        const auto start(issued - 60);
        const uint128_t range(60 * 60 * 24);

        const Ticket ticket{commit, issued, nonce, face, ratio, start, range, funder, recipient};
        const auto hash(ticket.Encode0(lottery, chain_, receipt));
        const auto signature(Sign(secret, Hash(Tie("\x19""Ethereum Signed Message:\n32", hash))));

        co_await Audit("grab", co_await endpoint_.Send(provider_, lottery, minimum_, grab(reveal, commit, issued, nonce, signature.v_, signature.r_, signature.s_, face, ratio, start, range, funder, recipient, receipt, {})));

        co_await show();

        co_await Audit("approve", co_await endpoint_.Send(customer_, token, minimum_, approve(lottery, 10)));
        co_await Audit("push", co_await endpoint_.Send(customer_, lottery, minimum_, push(signer, 10, 0)));

        co_await show();
    }

    template <typename Code_, typename ...Args_>
    task<void> Test1(const std::string &kind, const Address &lottery, Code_ &&move, Args_ ...args) {
        Log() << "==========" << std::endl;
        Log() << "lottery1 (" << kind << ")" << std::endl;

        static Selector<void, Address> bind("bind");
        static Selector<std::tuple<uint128_t, uint128_t, uint128_t, uint256_t, Bytes, uint256_t, std::tuple<Address, Bytes32>, std::tuple<Address, Bytes32>>, Address, Address, Args_...> look("look");
        static Selector<void, std::vector<Bytes32>> save("save");
        static Selector<void, Address, Args_..., uint128_t> warn("warn");

        typedef std::tuple<
            Bytes32 /*reveal*/, Bytes32 /*salt*/,
            uint256_t /*issued_nonce*/,
            uint256_t /*amount ratio*/,
            uint256_t /*start range funder v*/,
            Bytes32 /*r*/, Bytes32 /*s*/,
            Bytes /*receipt*/
        > Payment;

        static Selector<void,
            uint256_t /*recipient*/,
            Args_... /*token*/,
            Payment /*ticket*/,
            Bytes32 /*digest*/
        > grab1("grab");

        static Selector<void,
            uint256_t /*recipient*/,
            Args_... /*token*/,
            std::vector<Payment> /*tickets*/,
            std::vector<Bytes32>
        > grabN("grab");

        //const auto batch((co_await Receipt(co_await Constructor<>().Send(endpoint_, deployer_, maximum_, Bless(Load("../lot-ethereum/build/OrchidBatch.bin"))))).contract_);

        //co_await Audit("bind", co_await endpoint_.Send(customer_, lottery, minimum_, bind(1)));

      secret:
        const auto secret(Random<32>());
        const Address signer(Commonize(secret));
        if (Zeros(signer.buf()))
            goto secret;

        const auto funder(customer_);
        const auto recipient(provider_);

        const auto show([&]() -> task<void> {
            const auto [balance, escrow, warned, unlock, shared, bound, before, after] = co_await look.Call(endpoint_, "latest", lottery, 90000, customer_, signer, args...);
            Log() << std::dec << balance << " " << escrow << " | " << warned << " " << unlock << std::endl;
        });

        const bool direct(true);

        const auto pay([&]() {
            const Bytes receipt;

            const auto reveal(Nonzero<32>());
            const auto commit(Hash(Coder<Bytes32>::Encode(reveal)));

            const uint128_t face(2);
            const uint128_t ratio(Float(Two128) - 1);

            const auto issued(Timestamp());
            const auto start(issued - 60);
            const uint128_t range(60 * 60 * 24);

          sign:
            const auto salt(Nonzero<32>());
            const auto nonce(Nonzero<32>());

            const Ticket ticket{commit, issued, nonce, face, ratio, start, range, funder, recipient};
            const auto signature(Sign(secret, ticket.Encode1<Args_...>(lottery, chain_, args..., salt, direct)));
            if (Zeros(signature.operator Brick<65>()))
                goto sign;

            return Payment(
                reveal, salt,
                issued << 192 | nonce.num<uint256_t>() >> 64,
                uint256_t(face) << 128 | ratio,
                uint256_t(start) << 192 | uint256_t(range) << 168 | uint256_t(funder.num()) << 8 | signature.v_,
                signature.r_, signature.s_,
                receipt
            );
        });

        std::vector<Bytes32> digests;
        for (unsigned i(0); i != 7; ++i)
            digests.emplace_back(Nonzero<32>());
        co_await Audit("save", co_await endpoint_.Send(recipient, lottery, maximum_, save(digests)));

        const auto digest0(digests.back());
        digests.pop_back();
        const auto digest1(digests.back());
        digests.pop_back();

        co_await move(provider_, lottery, 1, provider_, 1, 0);
        co_await move(customer_, lottery, 20, signer, 4, 0);
        co_await show();

        std::vector<Payment> payments;
        payments.reserve(5);
        for (unsigned i(0); i != 5; ++i)
            payments.emplace_back(pay());

        const auto where([&]() -> uint256_t {
            return uint256_t(direct ? 1 : 0) << 160 | recipient.num();
        });

        co_await Audit("grabN", co_await endpoint_.Send(provider_, lottery, maximum_, grabN(where(), args..., payments, digests)));
        co_await show();

        co_await Audit("grabN", co_await endpoint_.Send(provider_, lottery, maximum_, grabN(where(), args..., {pay()}, {digest1})));
        co_await show();

        co_await Audit("grab1", co_await endpoint_.Send(provider_, lottery, minimum_, grab1(where(), args..., pay(), digest0)));
        co_await show();

        co_await Audit("grabN", co_await endpoint_.Send(provider_, lottery, maximum_, grabN(where(), args..., {pay()}, {})));
        co_await show();

        co_await Audit("grab1", co_await endpoint_.Send(provider_, lottery, minimum_, grab1(where(), args..., pay(), Number<uint256_t>(uint256_t(0)))));
        co_await show();

        co_await move(customer_, lottery, 10, signer, 0, 0);
        co_await show();
        co_await Audit("warn", co_await endpoint_.Send(customer_, lottery, minimum_, warn(signer, args..., 4)));
        co_await show();
        co_await move(customer_, lottery, 0, signer, -4, 21);
        co_await show();
    }

    auto Combine(const checked_int256_t &adjust, const uint256_t &retrieve) {
        return Complement(adjust) << 128 | retrieve;
    }

    task<void> Test() {
        const auto lottery1eth((co_await Receipt(co_await Constructor<>().Send(endpoint_, deployer_, maximum_, Bless(Load("../lot-ethereum/build/OrchidLottery1.bin"))))).contract_);
        const auto lottery1tok((co_await Receipt(co_await Constructor<>().Send(endpoint_, deployer_, maximum_, Bless(Load("../lot-ethereum/build/OrchidLottery1Token.bin"))))).contract_);

#if 1
        static Selector<bool, Address, uint256_t> approve("approve");
        static Selector<bool, Address, uint256_t> transfer("transfer");

        const auto token((co_await endpoint_(co_await Constructor<>().Send(endpoint_, customer_, maximum_, Bless(Load("../tok-ethereum/build/OrchidToken677.bin")))))->contract_);

        co_await Audit("transfer", co_await endpoint_.Send(customer_, token, minimum_, transfer(provider_, 10)));
        co_await Audit("transfer", co_await endpoint_.Send(customer_, token, minimum_, transfer(lottery1tok, 10)));

#if 1
        co_await Test0(token);
#endif

#if 1
        co_await Test1("erc20", lottery1tok, [&](const Address &sender, const Address &lottery, const uint256_t &value, const Address &signer, const checked_int256_t &adjust, const uint256_t &retrieve) -> task<void> {
            static Selector<void, Address, Address, uint256_t, uint256_t> move("move");
            if (value != 0)
                co_await Audit("approve", co_await endpoint_.Send(sender, token, minimum_, approve(lottery, value)));
            co_await Audit("move", co_await endpoint_.Send(sender, lottery, minimum_, move(signer, token, value, Combine(adjust, retrieve))));
        }, token);
#endif

#if 1
        co_await Test1("erc677", lottery1tok, [&](const Address &sender, const Address &lottery, const uint256_t &value, const Address &signer, const checked_int256_t &adjust, const uint256_t &retrieve) -> task<void> {
            static Selector<void, Address, uint256_t, Bytes> transferAndCall("transferAndCall");
            static Selector<void, Address, uint256_t> move("move");
            co_await Audit("move", co_await endpoint_.Send(sender, token, minimum_, transferAndCall(lottery, value, Beam(move(signer, Combine(adjust, retrieve))))));
        }, token);
#endif
#endif

#if 1
        co_await Test1("ether", lottery1eth, [&](const Address &sender, const Address &lottery, const uint256_t &value, const Address &signer, const checked_int256_t &adjust, const uint256_t &retrieve) -> task<void> {
            static Selector<void, Address, uint256_t> move("move");
            co_await Audit("move", co_await endpoint_.Send(sender, lottery, minimum_, value, move(signer, Combine(adjust, retrieve))));
        });
#endif
    }
};

task<int> Main(int argc, const char *const argv[]) {
    po::variables_map args;

    po::options_description group("general command line");
    group.add_options()
        ("help", "produce help message")
    ;

    po::options_description options;

    { po::options_description group("external resources");
    group.add_options()
        ("rpc", po::value<std::string>()->default_value("http://127.0.0.1:7545/"), "ethereum json/rpc private API endpoint")
    ; options.add(group); }

    po::store(po::parse_command_line(argc, argv, po::options_description()
        .add(group)
        .add(options)
    ), args);

    po::notify(args);

    if (args.count("help") != 0) {
        std::cout << po::options_description()
            .add(group)
            .add(options)
        << std::endl;
        co_return 0;
    }

    const auto origin(Break<Local>());
    Endpoint endpoint(origin, Locator::Parse(args["rpc"].as<std::string>()));

    std::vector<Address> accounts;
    for (const auto &account : co_await endpoint("personal_listAccounts", {})) {
        Address address(account.asString());
        co_await endpoint("personal_unlockAccount", {address, "", 60u});
        accounts.emplace_back(address);
    }

    uint256_t chain(co_await endpoint.Chain());
    Log() << std::dec << chain << std::endl;
    // XXX: work around a bug in Ganache
    if (chain == 1337) chain = 1;

    orc_assert(accounts.size() >= 3);
    Tester tester{endpoint, chain, accounts[0], accounts[1], accounts[2]};
    co_await tester.Test();

    co_return 0;
}

}

int main(int argc, char* argv[]) {
    _exit(orc::Wait(orc::Main(argc, argv)));
}
