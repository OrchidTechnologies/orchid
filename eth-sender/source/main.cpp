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

#include "base58.hpp"
#include "decimal.hpp"
#include "executor.hpp"
#include "float.hpp"
#include "load.hpp"
#include "local.hpp"
#include "nested.hpp"
#include "segwit.hpp"
#include "signed.hpp"
#include "sleep.hpp"
#include "ticket.hpp"
#include "trezor.hpp"

namespace orc {

namespace po = boost::program_options;

S<Origin> origin_;
S<Chain> chain_;
S<Executor> executor_;
uint256_t multiple_ = 1;
std::optional<uint256_t> nonce_;
std::optional<uint64_t> gas_;
Locator rpc_{"http", "127.0.0.1", "8545", "/"};

class Args :
    public std::deque<std::string>
{
  public:
    Args() = default;

    Args(std::initializer_list<std::string> args) {
        for (auto &arg : args)
            emplace_back(arg);
    }

    Args(int argc, const char *const argv[]) {
        for (int arg(0); arg != argc; ++arg)
            emplace_back(argv[arg]);
    }

    operator bool() {
        return !empty();
    }

    auto operator ()() {
        orc_assert(!empty());
        const auto value(std::move(front()));
        pop_front();
        return value;
    }
};

template <typename Type_>
struct Option;

template <typename Type_>
struct Option<std::optional<Type_>> {
static std::optional<Type_> _(std::string arg) {
    return Option<Type_>::_(arg);
} };

template <>
struct Option<bool> {
static bool _(std::string arg) {
    if (false);
    else if (arg == "true")
        return true;
    else if (arg == "false")
        return false;
    orc_assert_(false, "invalid bool " << arg);
} };

template <>
struct Option<std::string> {
static std::string _(std::string arg) {
    return arg;
} };

template <>
struct Option<Bytes32> {
static Bytes32 _(std::string arg) {
    return Bless(arg);
} };

template <>
struct Option<Decimal> {
static Decimal _(std::string_view arg) {
    return Decimal(arg);
} };

template <>
struct Option<uint64_t> {
static uint64_t _(std::string_view arg) {
    return To(arg);
} };

template <>
struct Option<uint256_t> {
static uint256_t _(std::string_view arg) {
    Decimal shift(1);

    auto last(arg.size());
    for (;;) {
        orc_assert(last-- != 0);
        if (false);
        else if (arg[last] == 'G')
            shift *= 1000000000;
        else break;
    }

    if (shift == 1)
        return uint256_t(arg);
    return uint256_t(Decimal(arg.substr(0, last + 1)) * shift);
} };

static Address TransferV("0x2c1820DBc112149b30b8616Bf73D552BEa4C9F1F");

template <>
struct Option<Address> {
static Address _(std::string arg) {
    if (false);
    else if (arg == "transferv") {
        return TransferV; }
    else if (arg == "OTT") {
        orc_assert_(*chain_ == 1, "OTT is not on chain " << chain_);
        return "0xff9978B7b309021D39a76f52Be377F2B95D72394"; }
    else if (arg == "OXT") {
        orc_assert_(*chain_ == 1, "OXT is not on chain " << chain_);
        return "0x4575f41308EC1483f3d399aa9a2826d74Da13Deb"; }
    else return arg;
} };

template <>
struct Option<Locator> {
static Locator _(std::string arg) {
    if (false);
    else if (arg == "cloudflare")
        arg = "https://cloudflare-eth.com/";
    else if (arg == "ganache")
        arg = "http://127.0.0.1:7545/";
    return arg;
} };

template <>
struct Option<S<Executor>> {
static cppcoro::shared_task<S<Executor>> _(std::string arg) {
    if (boost::algorithm::starts_with(arg, "@")) {
        const auto json(Parse(Load(arg.substr(1))));
        std::cout << json << std::endl;
        orc_insist(false);
    } else if (boost::algorithm::starts_with(arg, "m/")) {
        std::vector<uint32_t> indices;
        arg = arg.substr(2);
        for (const auto &span : Split(arg, {'/'})) {
            std::string index(span);
            orc_assert(!index.empty());
            bool flag;
            if (index[index.size() - 1] != '\'')
                flag = false;
            else {
                flag = true;
                index = index.substr(0, index.size() - 1);
            }
            indices.push_back(To(index) | (flag ? 1 << 31 : 0));
        }
        auto session(co_await TrezorSession::New(origin_));
        auto executor(co_await TrezorExecutor::New(std::move(session), indices));
        co_return std::move(executor);
    } else if (arg.size() == 64)
        co_return Make<SecretExecutor>(Bless(arg));
    else if (arg.size() == 42)
        co_return Make<UnlockedExecutor>(arg);
    else orc_assert(false);
} };

template <>
struct Option<Bytes> {
static Bytes _(std::string arg) {
    if (!arg.empty() && arg[0] == '@')
        arg = Load(arg.substr(1));
    return Bless(arg);
} };

template <typename ...Types_, size_t ...Indices_>
void Options(Args &args, std::tuple<Types_...> &options, std::index_sequence<Indices_...>) {
    ((std::get<Indices_>(options) = Option<Types_>::_(args[Indices_])), ...);
}

template <typename ...Types_>
auto Options(Args &args) {
    std::tuple<Types_...> options;
    Options(args, options, std::index_sequence_for<Types_...>());
    orc_assert(args.size() == sizeof...(Types_));
    return options;
}

task<int> Main(int argc, const char *const argv[]) { try {
    Args args(argc - 1, argv + 1);

    #define ORC_PARAM(name, prefix, suffix) \
        else if (arg == "--" #name) { \
            static bool seen; \
            orc_assert(!seen); \
            seen = true; \
            prefix name##suffix = Option<decltype(prefix name##suffix)>::_(args()); \
        }

    std::string executor;
    Flags flags;

    const auto command([&]() { for (;;) {
        const auto arg(args());
        orc_assert(!arg.empty());
        if (arg[0] != '-')
            return arg;
        if (false);
        ORC_PARAM(bid,flags.,_)
        ORC_PARAM(executor,,)
        ORC_PARAM(gas,,_)
        ORC_PARAM(nonce,,_)
        ORC_PARAM(rpc,,_)
        ORC_PARAM(verbose,flags.,_)
    } }());

    origin_ = Break<Local>();
    chain_ = co_await Chain::New(Endpoint{rpc_, origin_}, flags);

    if (executor.empty())
        executor_ = Make<MissingExecutor>();
    else
        executor_ = co_await Option<decltype(executor_)>::_(std::move(executor));

    const auto block([&]() -> task<Block> {
        const auto height(co_await chain_->Height());
        const auto block(co_await chain_->Header(height));
        co_return block;
    });

    if (false) {

    } else if (command == "account") {
        const auto [address] = Options<Address>(args);
        const auto [account] = co_await chain_->Get(co_await block(), address, nullptr);
        std::cout << account.balance_ << std::endl;

    } else if (command == "accounts") {
        for (const auto &account : co_await (*chain_)("personal_listAccounts", {}))
            std::cout << Address(account.asString()) << std::endl;

    } else if (command == "address") {
        std::cout << executor_->operator Address() << std::endl;

    } else if (command == "allowance") {
        const auto [token, address, recipient] = Options<Address, Address, Address>(args);
        static Selector<uint256_t, Address, Address> allowance("allowance");
        std::cout << co_await allowance.Call(*chain_, "latest", token, 90000, address, recipient) << std::endl;

    } else if (command == "approve") {
        const auto [token, recipient, amount] = Options<Address, Address, uint256_t>(args);
        static Selector<bool, Address, uint256_t> approve("approve");
        std::cout << (co_await executor_->Send(*chain_, {}, token, 0, approve(recipient, amount))).hex() << std::endl;

    } else if (command == "balance") {
        const auto [token, address] = Options<Address, Address>(args);
        static Selector<uint256_t, Address> balanceOf("balanceOf");
        std::cout << co_await balanceOf.Call(*chain_, "latest", token, 90000, address) << std::endl;

    } else if (command == "bid") {
        Options<>(args);
        std::cout << (co_await chain_->Bid()) << std::endl;

    } else if (command == "block") {
        const auto [height] = Options<uint64_t>(args);
        co_await chain_->Header(height);

    } else if (command == "cb58") {
        auto [data] = Options<Bytes>(args);
        std::cout << ToBase58(Tie(data, Hash2(data).Clip<28, 4>())) << std::endl;

    } else if (command == "code") {
        const auto [address] = Options<Address>(args);
        std::cout << (co_await chain_->Code(co_await block(), address)).hex() << std::endl;

    } else if (command == "deploy") {
        auto [amount, code, data] = Options<uint256_t, Bytes, Bytes>(args);
        std::cout << (co_await executor_->Send(*chain_, {}, std::nullopt, amount, Tie(code, data))).hex() << std::endl;

    } else if (command == "derive") {
        const auto [secret] = Options<Bytes32>(args);
        std::cout << ToUncompressed(Derive(secret)).hex() << std::endl;

    } else if (command == "deterministic-100") {
        auto [code] = Options<Bytes>(args);
        static Address factory("0x7A0D94F55792C434d74a40883C6ed8545E406D12");
        std::cout << (co_await executor_->Send(*chain_, {}, factory, 0, code)).hex() << std::endl;

    } else if (command == "deterministic-500") {
        auto [code] = Options<Bytes>(args);
        static Address factory("0x83aa38958768B9615B138339Cbd8601Fc2963D4d");
        std::cout << (co_await executor_->Send(*chain_, {}, factory, 0, code)).hex() << std::endl;

    } else if (command == "eip2470") {
        Options<>(args);
        const auto bid(flags.bid_ ? *flags.bid_ : uint256_t(100 * Ten9));
        static uint64_t gas(247000);
        Record record(0, bid, gas, std::nullopt, 0, Bless("608060405234801561001057600080fd5b50610134806100206000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c80634af63f0214602d575b600080fd5b60cf60048036036040811015604157600080fd5b810190602081018135640100000000811115605b57600080fd5b820183602082011115606c57600080fd5b80359060200191846001830284011164010000000083111715608d57600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929550509135925060eb915050565b604080516001600160a01b039092168252519081900360200190f35b6000818351602085016000f5939250505056fea26469706673582212206b44f8a82cb6b156bfcc3dc6aadd6df4eefd204bc928a4397fd15dacf6d5320564736f6c63430006020033"), *chain_, 27u, 0x247000u, 0x2470u);
        const auto [account] = co_await chain_->Get(co_await block(), record.from_, nullptr);
        if (account.nonce_ != 0)
            std::cout << record.hash_ << std::endl;
        else {
            orc_assert_(account.balance_ >= bid * gas, record.from_ << " <= " << bid * gas);
            std::cout << (co_await chain_->Send("eth_sendRawTransaction", {Subset(Implode({record.nonce_, record.bid_, record.gas_, record.target_, record.amount_, record.data_, 27u, 0x247000u, 0x2470u}))})).hex() << std::endl;
        }

    } else if (command == "factory") {
        Options<>(args);
        const auto bid(flags.bid_ ? *flags.bid_ : uint256_t(100 * Ten9));
        static uint64_t gas(100000);
        static const uint256_t twos("0x2222222222222222222222222222222222222222222222222222222222222222");
        Record record(0, bid, 100000, std::nullopt, 0, Bless("601f80600e600039806000f350fe60003681823780368234f58015156014578182fd5b80825250506014600cf3"), *chain_, 27u, twos, twos);
        const auto [account] = co_await chain_->Get(co_await block(), record.from_, nullptr);
        if (account.nonce_ != 0)
            std::cout << record.hash_ << std::endl;
        else {
            orc_assert_(account.balance_ >= bid * gas, record.from_ << " <= " << bid * gas);
            std::cout << (co_await chain_->Send("eth_sendRawTransaction", {Subset(Implode({record.nonce_, record.bid_, record.gas_, record.target_, record.amount_, record.data_, 27u, twos, twos}))})).hex() << std::endl;
        }

    } else if (command == "federation") {
        static Selector<std::tuple<std::string>> getFederationAddress("getFederationAddress");
        const auto [federation] = co_await getFederationAddress.Call(*chain_, "latest", "0x0000000000000000000000000000000001000006", 90000);
        std::cout << federation << std::endl;

    } else if (command == "generate") {
        Options<>(args);
        const auto secret(Random<32>());
        std::cout << secret.hex().substr(2) << std::endl;

    } else if (command == "hash") {
        auto [data] = Options<Bytes>(args);
        std::cout << HashK(data).hex() << std::endl;

    } else if (command == "height") {
        Options<>(args);
        std::cout << co_await chain_->Height() << std::endl;

    } else if (command == "hex") {
        Options<>(args);
        std::cout << "0x";
        std::cout << std::setbase(16) << std::setfill('0');
        for (;;) {
#ifdef _WIN32
            const auto byte(getchar());
#else
            const auto byte(getchar_unlocked());
#endif
            if (byte == EOF)
                break;
            std::cout << std::setw(2) << byte;
        }
        std::cout << std::endl;

    } else if (command == "lottery1:move") {
        const auto [lottery, amount, signer, adjust, retrieve] = Options<Address, uint256_t, Address, uint256_t, uint256_t>(args);
        static Selector<void, Address, uint256_t> move("move");
        std::cout << (co_await executor_->Send(*chain_, {}, lottery, amount, move(signer, adjust << 128 | retrieve))).hex() << std::endl;

    } else if (command == "nonce") {
        const auto [address] = Options<Address>(args);
        const auto [account] = co_await chain_->Get(co_await block(), address, nullptr);
        std::cout << account.nonce_ << std::endl;

    } else if (command == "number") {
        const auto [number] = Options<uint256_t>(args);
        std::cout << "0x" << std::hex << number << std::endl;

    } else if (command == "p2pkh") {
        // https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses
        const auto [data] = Options<Bytes>(args);
        std::cout << ToBase58Check(Tie('\x00', HashR(Hash2(ToCompressed(Derive(data)))))) << std::endl;

    } else if (command == "receipt") {
        const auto [transaction] = Options<Bytes32>(args);
        for (;;)
            if (const auto receipt{co_await (*chain_)[transaction]}) {
                std::cout << receipt->contract_ << std::endl;
                break;
            } else co_await Sleep(1000);

    } else if (command == "rlp") {
        const auto [data] = Options<Bytes>(args);
        std::cout << Explode(data) << std::endl;

    } else if (command == "segwit") {
        // https://bitcointalk.org/index.php?topic=4992632.0
        const auto [data] = Options<Bytes>(args);
        std::cout << ToSegwit(HashR(Hash2(data))) << std::endl;

    } else if (command == "send") {
        const auto [recipient, amount, data] = Options<Address, uint256_t, Bytes>(args);
        std::cout << (co_await executor_->Send(*chain_, {.nonce = nonce_, .gas = gas_}, recipient, amount, data)).hex() << std::endl;

    } else if (command == "singleton-100") {
        auto [code, salt] = Options<Bytes, Bytes32>(args);
        static Selector<Address, Bytes, Bytes32> deploy("deploy");
        static Address factory("0xce0042B868300000d44A59004Da54A005ffdcf9f");
        std::cout << (co_await executor_->Send(*chain_, {.gas = 3000000}, factory, 0, deploy(code, salt))).hex() << std::endl;

    } else if (command == "singleton-500") {
        auto [code, salt] = Options<Bytes, Bytes32>(args);
        static Selector<Address, Bytes, Bytes32> deploy("deploy");
        static Address factory("0xe14b5ae0d1e8a4e9039d40e5bf203fd21e2f6241");
        std::cout << (co_await executor_->Send(*chain_, {.gas = 3000000}, factory, 0, deploy(code, salt))).hex() << std::endl;

    } else if (command == "submit") {
        const auto [raw] = Options<Bytes>(args);
        std::cout << (co_await chain_->Send("eth_sendRawTransaction", {raw})).hex() << std::endl;

    } else if (command == "transfer") {
        const auto [token, recipient, amount, data] = Options<Address, Address, uint256_t, Bytes>(args);
        static Selector<bool, Address, uint256_t> transfer("transfer");
        static Selector<void, Address, uint256_t, Bytes> transferAndCall("transferAndCall");
        std::cout << (co_await executor_->Send(*chain_, {}, token, 0, data.size() == 0 ?
            transfer(recipient, amount) : transferAndCall(recipient, amount, data))).hex() << std::endl;

    } else if (command == "transferv") {
        orc_assert(nonce_);
        const auto [token, multiple] = Options<Address, uint256_t>(args);

        typedef std::tuple<Address, uint256_t> Send;
        std::vector<Send> sends;
        uint256_t total(0);

        const auto csv(Load(std::to_string(uint64_t(*nonce_)) + ".csv"));
        for (auto line : Split(csv, {'\n'})) {
            if (line.size() == 0 || line[0] == '#')
                continue;
            if (line[line.size() - 1] == '\r') {
                line -= 1;
                if (line.size() == 0)
                    continue;
            }

            const auto comma(Find(line, {','}));
            orc_assert(comma);
            auto [recipient, amount] = Split(line, *comma);
            const auto &send(sends.emplace_back(std::string(recipient), uint256_t(Option<Decimal>::_(amount) * Decimal(multiple))));
            std::cout << "transfer " << token << " " << std::get<0>(send) << " " << std::get<1>(send) << " 0x" << std::endl;
            total += std::get<1>(send);
        }

        std::cout << "total = " << total << std::endl;

        static Selector<void, Address, std::vector<Send>> transferv("transferv");
        std::cout << (co_await executor_->Send(*chain_, {.nonce = nonce_}, TransferV, 0, transferv(token, sends))).hex() << std::endl;

    } else if (command == "verify") {
        auto [height] = Options<uint64_t>(args);
        do {
            co_await chain_->Header(height);
            if (height % 1000 == 0)
                std::cerr << height << std::endl;
        } while (height--);

    } else if (command == "wif") {
        // https://en.bitcoin.it/wiki/Wallet_import_format
        // prefix with 0x80 for mainnet and 0xEF for testnet
        // suffix with 0x01 if this will be a compressed key
        const auto [data] = Options<Bytes>(args);
        std::cout << ToBase58Check(data) << std::endl;

    } else orc_assert_(false, "unknown command " << command);

    co_return 0;
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    co_return 1;
} }

}

int main(int argc, char* argv[]) {
    _exit(orc::Wait(orc::Main(argc, argv)));
}
