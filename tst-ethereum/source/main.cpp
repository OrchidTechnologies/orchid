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

    uint256_t audited_ = 0;

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
        audited_ += receipt.gas_;
        Log() << (receipt.status_ ? '+' : '-') << transaction << " " << name << ": " << std::dec << receipt.gas_ << std::endl;
        co_return receipt.status_;
    }

    void Audit() {
        Log() << "TOTAL: " << std::dec << audited_ << std::endl;
        audited_ = 0;
    }

    task<void> Test0(const Address &token) {
        Log() << "lottery0" << std::endl;

        static Selector<bool, Address, uint256_t> approve("approve");
        static Selector<bool, Address, uint256_t> transfer("transfer");

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

        const auto secret(Random<32>());
        const Address signer(Commonize(secret));

        const auto lottery((co_await Receipt(co_await Constructor<Address>().Send(endpoint_, deployer_, maximum_, Bless(Load("../lot-ethereum/build/OrchidLottery0.bin")), token))).contract_);

        const auto show([&]() -> task<void> {
            const auto [balance, escrow, unlock, verify, codehash, shared] = co_await look.Call(endpoint_, "latest", lottery, 90000, customer_, signer);
            Log() << std::dec << balance << " " << escrow << " | " << unlock << std::endl;
        });

        co_await Audit("transfer", co_await transfer.Send(endpoint_, customer_, token, minimum_, provider_, 10));
        Audit();

        co_await Audit("approve", co_await approve.Send(endpoint_, customer_, token, minimum_, lottery, 10));
        co_await Audit("push", co_await push.Send(endpoint_, customer_, lottery, maximum_, signer, 10, 4));

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

        co_await Audit("grab", co_await grab.Send(endpoint_, provider_, lottery, minimum_, reveal, commit, issued, nonce, signature.v_, signature.r_, signature.s_, face, ratio, start, range, funder, recipient, receipt, {}));

        co_await show();
        Audit();

        co_await Audit("approve", co_await approve.Send(endpoint_, customer_, token, minimum_, lottery, 10));
        co_await Audit("push", co_await push.Send(endpoint_, customer_, lottery, minimum_, signer, 10, 0));

        co_await show();
        Audit();

        Log() << "==========" << std::endl;
    }

    task<void> Test1() {
        Log() << "lottery1" << std::endl;

        static Selector<void, Address, std::vector<Bytes>> run("run");

        static Selector<std::tuple<uint128_t, uint128_t, uint128_t, uint256_t, Bytes, uint256_t, std::tuple<Address, Bytes32>, std::tuple<Address, Bytes32>>, Address, Address> look("look");
        static Selector<void, Address, uint256_t, uint256_t, uint256_t> move("move");
        static Selector<void, std::vector<Bytes32>> save("save");
        static Selector<void, Address, uint128_t> warn("warn");

        typedef std::tuple<
            Bytes32 /*reveal*/, Bytes32 /*salt*/,
            uint256_t /*issued*/, Bytes32 /*nonce*/,
            uint256_t /*start*/, uint128_t /*range*/,
            uint128_t /*amount*/, uint128_t /*ratio*/,
            Address /*funder*/, Bytes /*receipt*/,
            uint8_t /*v*/, Bytes32 /*r*/, Bytes32 /*s*/
        > Payment;

        static Selector<void,
            Address /*recipient*/,
            Payment /*ticket*/
        > grab1("grab");

        static Selector<void,
            Address /*recipient*/,
            std::vector<Payment> /*tickets*/,
            std::vector<Bytes32>
        > grabN("grab");

        //const auto batch((co_await Receipt(co_await Constructor<>().Send(endpoint_, deployer_, maximum_, Bless(Load("../lot-ethereum/build/OrchidBatch.bin"))))).contract_);

#if 0
        //const Address lottery("0x3675d91e95e8Edb6022fb4B3BB86fBf7eb1Ad8f2");
        const Address lottery("0x0AD1Bf8051B37A7c2b13e31780437Ca05e55bBE3");
#else
        const auto lottery((co_await Receipt(co_await Constructor<>().Send(endpoint_, deployer_, maximum_, Bless(Load("../lot-ethereum/build/OrchidLottery1.bin"))))).contract_);
        Log() << lottery << std::endl;
#endif

        const auto secret(Random<32>());
        const Address signer(Commonize(secret));

        const auto funder(customer_);
        const auto recipient(provider_);

        const auto show([&]() -> task<void> {
            const auto [balance, escrow, warned, unlock, shared, bound, before, after] = co_await look.Call(endpoint_, "latest", lottery, 90000, customer_, signer);
            Log() << std::dec << balance << " " << escrow << " | " << warned << " " << unlock << std::endl;
        });

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
            const auto signature(Sign(secret, ticket.Encode1(lottery, chain_, salt)));
            if (Zeros(signature.operator Brick<65>()))
                goto sign;

            return Payment(reveal, salt, issued, nonce, start, range, face, ratio, funder, receipt, signature.v_, signature.r_, signature.s_);
        });

        co_await Audit("move", co_await move.Send(endpoint_, customer_, lottery, minimum_, 10, signer, 0, 4, 0));
        co_await Audit("grab", co_await grab1.Send(endpoint_, provider_, lottery, minimum_, recipient, pay()));
        Audit();

        std::vector<Bytes32> digests;
        for (unsigned i(0); i != 5; ++i)
            digests.emplace_back(Nonzero<32>());
        co_await Audit("save", co_await save.Send(endpoint_, recipient, lottery, maximum_, digests));
        Audit();

        std::vector<Payment> payments;
        payments.reserve(5);
        for (unsigned i(0); i != 5; ++i)
            payments.emplace_back(pay());
        co_await Audit("grab", co_await grabN.Send(endpoint_, provider_, lottery, maximum_, recipient, payments, digests));
        Audit();

        co_await show();
        co_await Audit("move", co_await move.Send(endpoint_, customer_, lottery, minimum_, 10, signer, 0, 0, 0));
        co_await show();
        co_await Audit("warn", co_await warn.Send(endpoint_, customer_, lottery, minimum_, signer, 4));
        co_await show();
        co_await Audit("move", co_await move.Send(endpoint_, customer_, lottery, minimum_, 0, signer, 4, 0, 19));
        co_await show();

        Audit();

        Log() << "==========" << std::endl;
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

    const auto token((co_await endpoint(co_await Constructor<>().Send(endpoint, accounts[1], maximum_, Bless(Load("../tok-ethereum/build/OrchidToken.bin")))))->contract_);
    co_await tester.Test0(token);

    co_await tester.Test1();

    co_return 0;
}

}

int main(int argc, char* argv[]) {
    _exit(orc::Wait(orc::Main(argc, argv)));
}
