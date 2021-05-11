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


#include <boost/algorithm/string.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include "executor.hpp"
#include "float.hpp"
#include "load.hpp"
#include "local.hpp"
#include "nested.hpp"
#include "signed.hpp"
#include "sleep.hpp"
#include "ticket.hpp"
#include "time.hpp"

#define EVM_BASIC 21000
#define EVM_ECDSA 3000
#define EVM_EVENT_ARG 256
#define EVM_EVENT_IDX 375
#define EVM_STORE_NEW 15000
#define EVM_STORE_SET 5000
#define EVM_STORE_GET 800

namespace orc {

namespace po = boost::program_options;

static const Address OXT("0x4575f41308EC1483f3d399aa9a2826d74Da13Deb");

bool Zeros(const Region &data) {
    return memchr(data.data(), '\0', data.size()) != nullptr;
}

template <size_t Size_>
Brick<Size_> Nonzero() {
    for (;;) {
        const auto value(Random<Size_>());
        if (!Zeros(value))
            return value;
    }
}

struct Tester {
    Chain &chain_;

    const Executor &deployer_;
    const Executor &customer_;
    const Executor &provider_;

    task<Receipt> Receipt(const Bytes32 &transaction) {
        for (;;) {
            if (auto maybe{co_await chain_[transaction]}) {
                auto &receipt(*maybe);
                co_return std::move(receipt);
            }
            co_await Sleep(1000);
        }
    }

    task<bool> Audit(const std::string &name, const Bytes32 &transaction, uint64_t gas = 0) {
        const auto receipt(co_await Receipt(transaction));
        Log() << (receipt.status_ ? '+' : '-') << transaction << " " << name << ": " << std::dec << receipt.gas_ << " " << gas << " " << (gas == 0 ? 0 : int64_t(receipt.gas_) - int64_t(gas)) << std::endl;
        co_return receipt.status_;
    }

    task<void> Test0(const Secret &secret, const Address &signer, const Address &token, const Address &lottery, const Bytes &receipt) {
        Log() << "==========" << std::endl;
        Log() << "lottery0" << std::endl;

        static Selector<bool, Address, uint256_t> approve("approve");

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

        const auto show([&]() -> task<void> {
            const auto [balance, escrow, unlock, verify, codehash, shared] = co_await look.Call(chain_, "latest", lottery, 90000, customer_, signer);
            Log() << std::dec << balance << " " << escrow << " | " << unlock << std::endl;
        });

        co_await Audit("approve", co_await customer_.Send(chain_, {}, token, 0, approve(lottery, 10)));
        co_await Audit("push", co_await customer_.Send(chain_, {}, lottery, 0, push(signer, 10, 4)));

        co_await show();

        const auto reveal(Nonzero<32>());
        const auto commit(HashK(reveal));

        const auto nonce(Nonzero<32>());

        const auto &funder(customer_);
        const auto &recipient(provider_);

        const uint128_t face(2);
        const uint128_t ratio(Float(Two128) - 1);

        const auto issued(Timestamp());
        const auto start(issued - 60);
        const uint128_t range(60 * 60 * 24);

        const Ticket0 ticket{commit, issued, nonce, face, ratio, start, range, funder, recipient};
        const auto hash(ticket.Encode(lottery, chain_, receipt));
        const auto signature(Sign(secret, HashK(Tie("\x19""Ethereum Signed Message:\n32", hash))));

        co_await Audit("grab", co_await provider_.Send(chain_, {}, lottery, 0, grab(reveal, commit, issued, nonce, signature.v_ + 27, signature.r_, signature.s_, face, ratio, start, range, funder, recipient, receipt, {})));

        co_await show();

        co_await Audit("approve", co_await customer_.Send(chain_, {}, token, 0, approve(lottery, 10)));
        co_await Audit("push", co_await customer_.Send(chain_, {}, lottery, 0, push(signer, 10, 0)));

        co_await show();
    }

    template <typename Edit_>
    task<void> Test1(const std::string &kind, const Address &lottery, Edit_ &&edit, const Address &token) {
        Log() << "==========" << std::endl;
        Log() << "lottery1 (" << kind << ")" << std::endl;

        static Selector<std::tuple<uint256_t, uint256_t>, Address, Address, Address> read("read");
        static Selector<void, uint256_t, Bytes32> save("save");
        static Selector<void, Address, Address, uint128_t> warn("warn");

        static Selector<void,
            Address /*token*/,
            Address /*recipient*/,
            std::vector<Payment1> /*tickets*/,
            std::vector<Bytes32> /*refunds*/
        > claim("claim");

        struct Account {
            Secret secret_;
            Address signer_;

            unsigned balance_;
            unsigned escrow_;

            Account(const Secret &secret, const Address &signer) :
                secret_(secret),
                signer_(signer),
                balance_(0),
                escrow_(0)
            {
            }
        };

        std::vector<Account> accounts;

        for (unsigned i(0); i != 3; ++i) {
          secret:
            const auto secret(Random<32>());
            const Address signer(Derive(secret));
            if (Zeros(signer.buf()))
                goto secret;
            accounts.emplace_back(secret, signer);
        }

        const auto &funder(customer_);
        const auto &recipient(provider_);

        const auto check([&](Account &account, signed adjust) -> task<void> {
            account.balance_ += adjust;
            const auto [escrow_balance, unlock_warned] = co_await read.Call(chain_, "latest", lottery, 90000, token, customer_, account.signer_);
            //Log() << std::dec << uint128_t(escrow_balance) << " " << uint128_t(escrow_balance >> 128) << std::endl;
            orc_assert(uint128_t(escrow_balance) == account.balance_);
            orc_assert(uint128_t(escrow_balance >> 128) == account.escrow_);
            if (unlock_warned << 64 != 0) {
                const auto warned((uint64_t(unlock_warned)));
                const auto unlock(uint128_t(unlock_warned >> 128));
                Log() << std::dec << warned << " " << unlock << std::endl;
            }
        });


        const auto payment([&](Account &account) {
            const auto reveal(Nonzero<32>());
            const auto commit(HashK(reveal));

            const uint128_t face(1);
            const uint64_t ratio(-1);

            const auto issued(Timestamp() - 60);
            const uint32_t expire(20 + 60 * 60 * 60);

            const auto data(Nonzero<32>());

          sign:
            const auto nonce(Nonzero<8>());

            const Ticket1 ticket{recipient, commit, issued, nonce, face, expire, ratio, funder, data};
            const auto signature(Sign(account.secret_, ticket.Encode(lottery, chain_, token)));
            if (Zeros(signature.operator Brick<65>()))
                goto sign;

            return ticket.Payment(reveal, signature);
        });

        const auto payments([&](unsigned count) {
            orc_assert(count <= accounts.size());
            std::vector<Payment1> payments;
            payments.reserve(count);
            for (unsigned i(0); i != count; ++i)
                payments.emplace_back(payment(accounts[i]));
            return payments;
        });


      seed:
        const auto seed(Nonzero<32>());
        const unsigned count(100);
        std::vector<Bytes32> saved; {
            auto refund(HashK(Tie(HashK(Tie(seed, recipient)), Address())));
            for (unsigned i(0); i != count; ++i) {
                if (!Zeros(refund))
                    saved.emplace_back(refund);
                refund = HashK(refund);
            }
        }
        if (saved.size() < 75)
            goto seed;
        co_await Audit("save", co_await recipient.Send(chain_, {}, lottery, 0, save(count, seed)));

        const auto refunds([&](unsigned count) {
            orc_assert(saved.size() >= count);
            std::vector<Bytes32> array(saved.end() - count, saved.end());
            saved.resize(saved.size() - count);
            return array;
        });


        co_await edit(provider_, lottery, 1, provider_, 1, 0, 0);

        for (Account &account : accounts) {
            co_await edit(customer_, lottery, 85, account.signer_, 4, 0, 0);
            account.escrow_ += 4;
            co_await check(account, 81);
        }

        static const auto update(
            EVM_STORE_GET+EVM_STORE_SET+
            EVM_EVENT_IDX*2+EVM_EVENT_ARG*2+
        0);

        static const unsigned perp(
            EVM_ECDSA+
            EVM_STORE_GET+EVM_STORE_NEW+EVM_STORE_SET+
            EVM_STORE_GET+
            update+
            6*32*16+
        2977);

        static const unsigned perd(
            16*32+EVM_STORE_GET+EVM_STORE_SET+
        257);

        Log() << std::dec << update << " " << perp << " " << perd << std::endl;

        for (unsigned p(0); p != 4; ++p)
            for (unsigned d(0); d != (p+1)*2+1; ++d) {
                std::ostringstream name;
                name << "claim(" << std::hex << std::uppercase << p << "," << d << ")";

                const auto positive(
                    EVM_BASIC+ perp*p+
                    4*12+(token==Address()?4:16)*20+
                    4*31+(p==0?4:16+update+678)+
                    4*31+(d==0?4:16)+perd*d+
                1652);

                auto negative(EVM_STORE_NEW*d);

                if (negative > positive / 2) negative = positive / 2;
                co_await Audit(name.str(), co_await provider_.Send(chain_, {}, lottery, 0, claim(token, recipient, payments(p), refunds(d))), positive - negative);
                for (unsigned i(0); i != p; ++i)
                    co_await check(accounts[i], -1);
            }

        auto &account(accounts[0]);

        co_await edit(customer_, lottery, 10, account.signer_, 0, 0, 0);
        co_await check(account, 10);

        co_await edit(customer_, lottery, 0, account.signer_, 0, 4, 0);
        co_await check(account, 0);

        co_await edit(customer_, lottery, 0, account.signer_, -4, 0, 21);
        account.escrow_ -= 4;
        co_await check(account, 4-21);
    }

    auto Combine(const checked_int256_t &adjust, const uint256_t &retrieve) {
        return Complement(adjust) << 128 | retrieve;
    }

    task<void> Test() {
        const auto lottery1((co_await Receipt(co_await deployer_.Send(chain_, {}, std::nullopt, 0, Constructor<uint64_t>(Bless(Load("../lot-ethereum/build/OrchidLottery1.bin")))(0)))).contract_);

#if 1
        static Selector<void, bool, std::vector<Address>> enroll("enroll");
        co_await Audit("enroll", co_await customer_.Send(chain_, {}, lottery1, 0, enroll(false, {})));
        co_await Audit("enroll", co_await customer_.Send(chain_, {}, lottery1, 0, enroll(false, {provider_})));
#endif

#if 1
        static Selector<bool, Address, uint256_t> approve("approve");
        static Selector<uint256_t, Address> balanceOf("balanceOf");
        static Selector<bool, Address, uint256_t> transfer("transfer");
        static Selector<void, Address, uint256_t, Bytes> transferAndCall("transferAndCall");

      token:
        const auto token((co_await Receipt(co_await customer_.Send(chain_, {}, std::nullopt, 0, Constructor<>(Bless(Load("../tok-ethereum/build/OrchidToken677.bin")))()))).contract_);
        if (Zeros(token.buf()))
            goto token;

        co_await Audit("transfer", co_await customer_.Send(chain_, {}, token, 0, transfer(provider_, 500)));
        co_await Audit("transfer", co_await customer_.Send(chain_, {}, token, 0, transfer(lottery1, 10)));

#if 1
      secret:
        const auto secret(Random<32>());
        const Address signer(Derive(secret));
        if (Zeros(signer.buf()))
            goto secret;

        const auto lottery0((co_await Receipt(co_await deployer_.Send(chain_, {}, std::nullopt, 0, Constructor<Address>(Bless(Load("../lot-ethereum/build/OrchidLottery0.bin")))(token)))).contract_);
#if 1
        const auto verifier((co_await Receipt(co_await deployer_.Send(chain_, {}, std::nullopt, 0, Constructor<>(Bless(Load("../lot-ethereum/build/OrchidPassword.bin")))()))).contract_);
        static Selector<void, Address, Address, Bytes> bind0("bind");
        co_await Audit("bind", co_await customer_.Send(chain_, {}, lottery0, 0, bind0(signer, verifier, {})));
        const Bytes receipt("password");
#else
        const Bytes receipt;
#endif
        co_await Test0(secret, signer, token, lottery0, receipt);
#endif

#if 1
        co_await Test1("erc20", lottery1, [&](const Executor &sender, const Address &lottery, const uint256_t &value, const Address &signer, const checked_int256_t &adjust, const checked_int256_t &warn, const uint256_t &retrieve) -> task<void> {
            static Selector<void, Address, uint256_t, Address, checked_int256_t, checked_int256_t, uint256_t> edit("edit");
            if (value != 0)
                co_await Audit("approve", co_await sender.Send(chain_, {}, token, 0, approve(lottery, value)));
            co_await Audit("edit", co_await sender.Send(chain_, {}, lottery, 0, edit(token, value, signer, adjust, warn, retrieve)));
        }, token);
#endif

#if 1
        Log() << std::dec << co_await balanceOf.Call(chain_, "latest", token, 90000, lottery1) << std::endl;
        co_await Test1("erc677", lottery1, [&](const Executor &sender, const Address &lottery, const uint256_t &value, const Address &signer, const checked_int256_t &adjust, const checked_int256_t &warn, const uint256_t &retrieve) -> task<void> {
            Log() << std::dec << co_await balanceOf.Call(chain_, "latest", token, 90000, lottery1) << std::endl;
            static Selector<void, Address, checked_int256_t, checked_int256_t, uint256_t> edit("edit");
            co_await Audit("edit", co_await sender.Send(chain_, {}, token, 0, transferAndCall(lottery, value, Beam(edit(signer, adjust, warn, retrieve)))));
            Log() << std::dec << co_await balanceOf.Call(chain_, "latest", token, 90000, lottery1) << std::endl;
        }, token);
        Log() << std::dec << co_await balanceOf.Call(chain_, "latest", token, 90000, lottery1) << std::endl;
#endif
#endif

#if 1
        co_await Test1("ether", lottery1, [&](const Executor &sender, const Address &lottery, const uint256_t &value, const Address &signer, const checked_int256_t &adjust, const checked_int256_t &warn, const uint256_t &retrieve) -> task<void> {
            static Selector<void, Address, checked_int256_t, checked_int256_t, uint256_t> edit("edit");
            co_await Audit("edit", co_await sender.Send(chain_, {}, lottery, value, edit(signer, adjust, warn, retrieve)));
        }, 0);
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

    const S<Base> base(Break<Local>());
    const auto chain(co_await Chain::New({args["rpc"].as<std::string>(), base}, {}));

    std::vector<UnlockedExecutor> accounts;
    for (const auto &account : co_await (*chain)("personal_listAccounts", {})) {
        Address address(account.asString());
        co_await (*chain)("personal_unlockAccount", {address, "", 60u});
        accounts.emplace_back(address);
    }

    orc_assert(accounts.size() >= 3);
    Tester tester{*chain, accounts[0], accounts[1], accounts[2]};
    co_await tester.Test();

    co_return 0;
}

}

int main(int argc, char* argv[]) {
    _exit(orc::Wait(orc::Main(argc, argv)));
}
