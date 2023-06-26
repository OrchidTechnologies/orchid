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
#include "currency.hpp"
#include "decimal.hpp"
#include "executor.hpp"
#include "float.hpp"
#include "load.hpp"
#include "local.hpp"
#include "nested.hpp"
#include "pricing.hpp"
#include "segwit.hpp"
#include "signed.hpp"
#include "sleep.hpp"
#include "ticket.hpp"
#include "time.hpp"
#include "trezor.hpp"
#include "uniswap.hpp"

namespace orc {

// NOLINTBEGIN(cppcoreguidelines-avoid-non-const-global-variables)
S<Base> base_;
S<Chain> chain_;
S<Executor> executor_;
std::string currency_;
uint256_t multiple_ = 1;
std::optional<uint256_t> nonce_;
std::optional<uint64_t> gas_;
std::optional<uint64_t> height_;
Locator rpc_{{"http", "127.0.0.1", "8545"}, "/"};
// NOLINTEND(cppcoreguidelines-avoid-non-const-global-variables)

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
        auto value(std::move(front()));
        pop_front();
        return value;
    }
};

template <typename Type_>
struct Option;

template <typename Type_>
struct Option<std::optional<Type_>> {
static std::optional<Type_> _(std::string_view arg) {
    if (arg.empty())
        return std::nullopt;
    return Option<Type_>::_(arg);
} };

template <>
struct Option<bool> {
static bool _(std::string_view arg) {
    if (false);
    else if (arg == "true")
        return true;
    else if (arg == "false")
        return false;
    orc_assert_(false, "invalid bool " << arg);
} };

template <>
struct Option<std::string> {
static std::string _(std::string_view arg) {
    return std::string(arg);
} };

template <>
struct Option<Bytes32> {
static Bytes32 _(std::string_view arg) {
    return Bless(arg);
} };

template <>
struct Option<Key> {
static Key _(std::string_view arg) {
    return ToKey(Bless(arg));
} };

template <>
struct Option<Signature> {
static Signature _(std::string_view arg) {
    return Brick<65>(Bless(arg));
} };

template <>
struct Option<Decimal> {
static Decimal _(std::string_view arg) {
    return Decimal(arg);
} };

template <>
struct Option<uint8_t> {
static uint64_t _(std::string_view arg) {
    return To<uint8_t>(arg);
} };

template <>
struct Option<uint64_t> {
static uint64_t _(std::string_view arg) {
    return To<uint64_t>(arg);
} };

template <>
struct Option<int> {
static int _(std::string_view arg) {
    return To<int>(arg);
} };

template <>
struct Option<uint256_t> {
static uint256_t _(std::string_view arg) {
    if (arg == "-1")
        return ~uint256_t(0);

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

template <>
struct Option<uint128_t> {
static uint128_t _(std::string_view arg) {
    return uint128_t(Option<uint256_t>::_(arg));
} };

// XXX: this is incorrect because boost doesn't understand 2's compliment
template <>
struct Option<checked_int256_t> {
static checked_int256_t _(std::string_view arg) {
    orc_assert(!arg.empty());
    if (arg[0] != '-')
        return Option<uint256_t>::_(arg);
    const auto value(Option<uint256_t>::_(arg.substr(1)));
    return -checked_int256_t(value);
} };

static const Address TransferV("0x2c1820DBc112149b30b8616Bf73D552BEa4C9F1F");

template <>
struct Option<Address> {
static Address _(std::string_view arg) {
    if (false);
    else if (arg == "0") {
        return "0x0000000000000000000000000000000000000000"; }
    else if (arg == "this") {
        return executor_->operator Address(); }

    else if (arg == "factory@100") {
        return "0x7A0D94F55792C434d74a40883C6ed8545E406D12"; }
    else if (arg == "factory@500") {
        return "0x83aa38958768B9615B138339Cbd8601Fc2963D4d"; }

    else if (arg == "lottery0") {
        return "0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1"; }
    else if (arg == "lottery1") {
        return "0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82"; }

    else if (arg == "eip1820") {
        return "0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24"; }
    else if (arg == "eip2470") {
        return "0xce0042B868300000d44A59004Da54A005ffdcf9f"; }

    else if (arg == "transferv") {
        return TransferV; }

    else if (arg == "OTT") {
        orc_assert_(*chain_ == 1, "OTT is not on chain " << chain_);
        return "0xff9978B7b309021D39a76f52Be377F2B95D72394"; }
    else if (arg == "OXT") {
        orc_assert_(*chain_ == 1, "OXT is not on chain " << chain_);
        return "0x4575f41308EC1483f3d399aa9a2826d74Da13Deb"; }

    else if (arg == "DAI") {
        orc_assert_(*chain_ == 1, "DAI is not on chain " << chain_);
        return "0x6B175474E89094C44Da98b954EedeAC495271d0F"; }
    else if (arg == "GUSD") {
        orc_assert_(*chain_ == 1, "GUSD is not on chain " << chain_);
        return "0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd"; }
    else if (arg == "USDC") {
        orc_assert_(*chain_ == 1, "USDC is not on chain " << chain_);
        return "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"; }

    else if (arg == "WAVAX") {
        orc_assert_(*chain_ == 43114, "WAVAX is not on chain " << chain_);
        return "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7"; }

    else if (arg == "DAI-PSM-GUSD") {
        orc_assert_(*chain_ == 1, "DAI is not on chain " << chain_);
        return "0x204659B2Fd2aD5723975c362Ce2230Fba11d3900"; }
    else if (arg == "DAI-PSM-USDC") {
        orc_assert_(*chain_ == 1, "DAI is not on chain " << chain_);
        return "0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A"; }
    else if (arg == "DAI-PSM-USDP") {
        orc_assert_(*chain_ == 1, "DAI is not on chain " << chain_);
        return "0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf"; }

    else return arg;
} };

template <>
struct Option<std::optional<Address>> {
static std::optional<Address> _(std::string_view arg) {
    if (arg == "null")
        return std::nullopt;
    return Option<Address>::_(arg);
} };

template <>
struct Option<Locator> {
static Locator _(std::string_view arg) {
    if (false);
    else if (arg == "cloudflare")
        arg = "https://cloudflare-eth.com/";
    else if (arg == "ganache")
        arg = "http://127.0.0.1:7545/";
    return arg;
} };

template <>
struct Option<Any> {
static Any _(const std::string &arg) {
    return Parse(arg);
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
            indices.push_back(To<uint32_t>(index) | (flag ? 1 << 31 : 0));
        }
        auto session(co_await TrezorSession::New(base_));
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
std::tuple<Types_...> Options(Args &args, std::index_sequence<Indices_...>) {
    return std::tuple<Types_...>(Option<Types_>::_(args[Indices_])...);
}

template <typename ...Types_>
auto Options(Args &args) {
    // NOLINTNEXTLINE(clang-analyzer-core.StackAddressEscape)
    orc_assert(args.size() == sizeof...(Types_));
    return Options<Types_...>(args, std::index_sequence_for<Types_...>());
}

task<void> ScanState(const S<Chain> &chain, uint64_t height);
task<void> ScanStorage(const S<Chain> &chain, uint64_t height, const Address &address);

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
        auto arg(args());
        orc_assert(!arg.empty());
        if (arg[0] != '-')
            return arg;
        if (false);
        ORC_PARAM(bid,flags.,_)
        ORC_PARAM(height,,_)
        ORC_PARAM(currency,,_)
        ORC_PARAM(executor,,)
        ORC_PARAM(gas,,_)
        ORC_PARAM(nonce,,_)
        ORC_PARAM(rpc,,_)
        ORC_PARAM(verbose,flags.,_)
    } }());

    base_ = Break<Local>();
    chain_ = co_await Chain::New(Endpoint{rpc_, base_}, flags);

    if (executor.empty())
        executor_ = Make<MissingExecutor>();
    else
        executor_ = co_await Option<decltype(executor_)>::_(std::move(executor));

    const auto block([&]() -> cppcoro::shared_task<Block> {
        const auto height(height_ ? *height_ : co_await chain_->Height());
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
        const auto [key] = Options<Key>(args);
        std::cout << Address(key) << std::endl;

    } else if (command == "allowance") {
        const auto [token, address, recipient] = Options<Address, Address, Address>(args);
        static Selector<uint256_t, Address, Address> allowance("allowance");
        std::cout << co_await allowance.Call(*chain_, "latest", token, 90000, address, recipient) << std::endl;

    } else if (command == "approve") {
        const auto [token, recipient, amount] = Options<Address, Address, uint256_t>(args);
        static Selector<bool, Address, uint256_t> approve("approve");
        std::cout << (co_await executor_->Send(*chain_, {.nonce = nonce_}, token, 0, approve(recipient, amount))).hex() << std::endl;

    } else if (command == "avax") {
        // https://docs.avax.network/build/references/cryptographic-primitives
        const auto [key] = Options<Key>(args);
        std::cout << ToSegwit("avax", std::nullopt, HashR(Hash2(ToCompressed(key)))) << std::endl;

    } else if (command == "balance") {
        const auto [token, address] = Options<Address, Address>(args);
        static Selector<uint256_t, Address> balanceOf("balanceOf");
        std::cout << co_await balanceOf.Call(*chain_, "latest", token, 90000, address) << std::endl;

    } else if (command == "bid") {
        Options<>(args);
        std::cout << (co_await chain_->Bid()) << std::endl;

    } else if (command == "binance") {
        const auto [pair] = Options<std::string>(args);
        std::cout << co_await Binance(*base_, pair, 1) << std::endl;

    } else if (command == "block") {
        const auto [height] = Options<uint64_t>(args);
        std::cout << co_await (*chain_)("eth_getBlockByNumber", {height, true}) << std::endl;

    } else if (command == "block-rlp") {
        const auto [height] = Options<uint64_t>(args);
        std::cout << Str(co_await chain_->Call("debug_getBlockRlp", {unsigned(height)})) << std::endl;

    } else if (command == "bsc:transfer") {
        const auto [segwit, amount] = Options<std::string, uint256_t>(args);
        const auto recipient(FromSegwit(segwit));
        orc_assert(recipient.first == "bnb");
        const Address token("0x0000000000000000000000000000000000000000");
        const Address hub("0x0000000000000000000000000000000000001004");
        // https://raw.githubusercontent.com/binance-chain/bsc-genesis-contract/master/abi/tokenhub.abi
        static Selector<uint256_t> relayFee("relayFee");
        static Selector<bool, Address, Address, uint256_t, uint64_t> transferOut("transferOut");
        // XXX: gas is manually specified as eth_estimateGas failed to give this enough gas?! *sigh* :/
        std::cout << (co_await executor_->Send(*chain_, {.gas = 90000}, hub, amount + co_await relayFee.Call(*chain_, "latest", hub, 90000), transferOut(token, recipient.second.num<uint160_t>(), amount, Timestamp() + 1000))).hex() << std::endl;

    } else if (command == "cb58") {
        auto [data] = Options<Bytes>(args);
        std::cout << ToBase58(Tie(data, Hash2(data).Clip<28, 4>())) << std::endl;

    } else if (command == "chain") {
        Options<>(args);
        std::cout << chain_->operator const uint256_t &() << std::endl;

    } else if (command == "chainlink") {
        const auto [address] = Options<Address>(args);
        static Selector<uint256_t> latestAnswer("latestAnswer");
        std::cout << std::dec << co_await latestAnswer.Call(*chain_, "latest", address, 90000) << std::endl;

    } else if (command == "code") {
        const auto [address] = Options<Address>(args);
        std::cout << (co_await chain_->Code(co_await block(), address)).hex() << std::endl;

    } else if (command == "codehash") {
        const auto [height, address] = Options<uint64_t, Address>(args);
        Address contract;
        std::cout << Str(co_await chain_->Call("eth_call", {Multi{
            {"from", "0x0000000000000000000000000000000000000000"},
            {"to", contract},
            {"gas", uint64_t(90000)},
            {"data", Number<uint256_t>(address.num())},
        }, height, Multi{{contract.str(), Multi{{"code", "0x6000353f60005260206000f3"}}}}})) << std::endl;

    } else if (command == "create2") {
        auto [factory, salt, code, data] = Options<Address, uint256_t, Bytes, Bytes>(args);
        std::cout << Address(HashK(Tie(uint8_t(0xff), factory, salt, HashK(Tie(code, data)))).skip<12>().num<uint160_t>()) << std::endl;

    } else if (command == "dai:buygem") {
        auto [psm, buyer, amount] = Options<Address, Address, uint256_t>(args);
        static Selector<void, Address, uint256_t> buyGem("buyGem");
        std::cout << (co_await executor_->Send(*chain_, {.gas = gas_}, psm, 0, buyGem(buyer, amount))).hex() << std::endl;

    } else if (command == "dai:sellgem") {
        auto [psm, seller, amount] = Options<Address, Address, uint256_t>(args);
        static Selector<void, Address, uint256_t> sellGem("sellGem");
        std::cout << (co_await executor_->Send(*chain_, {.gas = gas_}, psm, 0, sellGem(seller, amount))).hex() << std::endl;

    } else if (command == "debug") {
        const auto [block] = Options<Bytes32>(args);
        const auto trace((co_await chain_->Call("debug_traceBlockByHash", {block, Multi{{"enableMemory", true}}})).as_array());
        std::cout << Unparse(trace) << std::endl;

    } else if (command == "deploy") {
        auto [factory, amount, code, data] = Options<std::optional<Address>, uint256_t, Bytes, Bytes>(args);
        std::cout << (co_await executor_->Send(*chain_, {.gas = gas_}, factory, amount, Tie(code, data))).hex() << std::endl;

    } else if (command == "derive") {
        const auto [secret] = Options<Bytes32>(args);
        std::cout << ToUncompressed(Derive(secret)).hex() << std::endl;

    } else if (command == "eip1820") {
        Options<>(args);
        const auto bid(flags.bid_ ? *flags.bid_ : uint256_t(100 * Ten9));
        static const uint256_t rs("0x1820182018201820182018201820182018201820182018201820182018201820");
        Record record(0, bid, 800000, std::nullopt, 0, Bless("608060405234801561001057600080fd5b506109c5806100206000396000f3fe608060405234801561001057600080fd5b50600436106100a5576000357c010000000000000000000000000000000000000000000000000000000090048063a41e7d5111610078578063a41e7d51146101d4578063aabbb8ca1461020a578063b705676514610236578063f712f3e814610280576100a5565b806329965a1d146100aa5780633d584063146100e25780635df8122f1461012457806365ba36c114610152575b600080fd5b6100e0600480360360608110156100c057600080fd5b50600160a060020a038135811691602081013591604090910135166102b6565b005b610108600480360360208110156100f857600080fd5b5035600160a060020a0316610570565b60408051600160a060020a039092168252519081900360200190f35b6100e06004803603604081101561013a57600080fd5b50600160a060020a03813581169160200135166105bc565b6101c26004803603602081101561016857600080fd5b81019060208101813564010000000081111561018357600080fd5b82018360208201111561019557600080fd5b803590602001918460018302840111640100000000831117156101b757600080fd5b5090925090506106b3565b60408051918252519081900360200190f35b6100e0600480360360408110156101ea57600080fd5b508035600160a060020a03169060200135600160e060020a0319166106ee565b6101086004803603604081101561022057600080fd5b50600160a060020a038135169060200135610778565b61026c6004803603604081101561024c57600080fd5b508035600160a060020a03169060200135600160e060020a0319166107ef565b604080519115158252519081900360200190f35b61026c6004803603604081101561029657600080fd5b508035600160a060020a03169060200135600160e060020a0319166108aa565b6000600160a060020a038416156102cd57836102cf565b335b9050336102db82610570565b600160a060020a031614610339576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b6103428361092a565b15610397576040805160e560020a62461bcd02815260206004820152601a60248201527f4d757374206e6f7420626520616e204552433136352068617368000000000000604482015290519081900360640190fd5b600160a060020a038216158015906103b85750600160a060020a0382163314155b156104ff5760405160200180807f455243313832305f4143434550545f4d4147494300000000000000000000000081525060140190506040516020818303038152906040528051906020012082600160a060020a031663249cb3fa85846040518363ffffffff167c01000000000000000000000000000000000000000000000000000000000281526004018083815260200182600160a060020a0316600160a060020a031681526020019250505060206040518083038186803b15801561047e57600080fd5b505afa158015610492573d6000803e3d6000fd5b505050506040513d60208110156104a857600080fd5b5051146104ff576040805160e560020a62461bcd02815260206004820181905260248201527f446f6573206e6f7420696d706c656d656e742074686520696e74657266616365604482015290519081900360640190fd5b600160a060020a03818116600081815260208181526040808320888452909152808220805473ffffffffffffffffffffffffffffffffffffffff19169487169485179055518692917f93baa6efbd2244243bfee6ce4cfdd1d04fc4c0e9a786abd3a41313bd352db15391a450505050565b600160a060020a03818116600090815260016020526040812054909116151561059a5750806105b7565b50600160a060020a03808216600090815260016020526040902054165b919050565b336105c683610570565b600160a060020a031614610624576040805160e560020a62461bcd02815260206004820152600f60248201527f4e6f7420746865206d616e616765720000000000000000000000000000000000604482015290519081900360640190fd5b81600160a060020a031681600160a060020a0316146106435780610646565b60005b600160a060020a03838116600081815260016020526040808220805473ffffffffffffffffffffffffffffffffffffffff19169585169590951790945592519184169290917f605c2dbf762e5f7d60a546d42e7205dcb1b011ebc62a61736a57c9089d3a43509190a35050565b600082826040516020018083838082843780830192505050925050506040516020818303038152906040528051906020012090505b92915050565b6106f882826107ef565b610703576000610705565b815b600160a060020a03928316600081815260208181526040808320600160e060020a031996909616808452958252808320805473ffffffffffffffffffffffffffffffffffffffff19169590971694909417909555908152600284528181209281529190925220805460ff19166001179055565b600080600160a060020a038416156107905783610792565b335b905061079d8361092a565b156107c357826107ad82826108aa565b6107b85760006107ba565b815b925050506106e8565b600160a060020a0390811660009081526020818152604080832086845290915290205416905092915050565b6000808061081d857f01ffc9a70000000000000000000000000000000000000000000000000000000061094c565b909250905081158061082d575080155b1561083d576000925050506106e8565b61084f85600160e060020a031961094c565b909250905081158061086057508015155b15610870576000925050506106e8565b61087a858561094c565b909250905060018214801561088f5750806001145b1561089f576001925050506106e8565b506000949350505050565b600160a060020a0382166000908152600260209081526040808320600160e060020a03198516845290915281205460ff1615156108f2576108eb83836107ef565b90506106e8565b50600160a060020a03808316600081815260208181526040808320600160e060020a0319871684529091529020549091161492915050565b7bffffffffffffffffffffffffffffffffffffffffffffffffffffffff161590565b6040517f01ffc9a7000000000000000000000000000000000000000000000000000000008082526004820183905260009182919060208160248189617530fa90519096909550935050505056fea165627a7a72305820377f4a2d4301ede9949f163f319021a6e9c687c292a5e2b2c4734c126b524e6c0029"), *chain_, 27u, rs, rs);
        const auto [account] = co_await chain_->Get(co_await block(), record.from_, nullptr);
        if (account.nonce_ != 0)
            std::cout << record.hash_ << std::endl;
        else {
            orc_assert_(account.balance_ >= bid * record.gas_, record.from_ << " <= " << bid * record.gas_);
            std::cout << (co_await chain_->Send("eth_sendRawTransaction", {Subset(Implode({record.nonce_, record.bid_, record.gas_, record.target_, record.amount_, record.data_, 27u, rs, rs}))})).hex() << std::endl;
        }

    } else if (command == "eip2470") {
        Options<>(args);
        const auto bid(flags.bid_ ? *flags.bid_ : uint256_t(100 * Ten9));
        Record record(0, bid, 247000, std::nullopt, 0, Bless("608060405234801561001057600080fd5b50610134806100206000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c80634af63f0214602d575b600080fd5b60cf60048036036040811015604157600080fd5b810190602081018135640100000000811115605b57600080fd5b820183602082011115606c57600080fd5b80359060200191846001830284011164010000000083111715608d57600080fd5b91908080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250929550509135925060eb915050565b604080516001600160a01b039092168252519081900360200190f35b6000818351602085016000f5939250505056fea26469706673582212206b44f8a82cb6b156bfcc3dc6aadd6df4eefd204bc928a4397fd15dacf6d5320564736f6c63430006020033"), *chain_, 27u, 0x247000u, 0x2470u);
        const auto [account] = co_await chain_->Get(co_await block(), record.from_, nullptr);
        if (account.nonce_ != 0)
            std::cout << record.hash_ << std::endl;
        else {
            orc_assert_(account.balance_ >= bid * record.gas_, record.from_ << " <= " << bid * record.gas_);
            std::cout << (co_await chain_->Send("eth_sendRawTransaction", {Subset(Implode({record.nonce_, record.bid_, record.gas_, record.target_, record.amount_, record.data_, 27u, 0x247000u, 0x2470u}))})).hex() << std::endl;
        }

    // https://github.com/Zoltu/deterministic-deployment-proxy
    } else if (command == "factory") {
        Options<>(args);
        const auto bid(flags.bid_ ? *flags.bid_ : uint256_t(100 * Ten9));
        static const uint256_t rs("0x2222222222222222222222222222222222222222222222222222222222222222");
        Record record(0, bid, 100000, std::nullopt, 0, Bless("601f80600e600039806000f350fe60003681823780368234f58015156014578182fd5b80825250506014600cf3"), *chain_, 27u, rs, rs);
        const auto [account] = co_await chain_->Get(co_await block(), record.from_, nullptr);
        if (account.nonce_ != 0)
            std::cout << record.hash_ << std::endl;
        else {
            orc_assert_(account.balance_ >= bid * record.gas_, record.from_ << " <= " << bid * record.gas_);
            std::cout << (co_await chain_->Send("eth_sendRawTransaction", {Subset(Implode({record.nonce_, record.bid_, record.gas_, record.target_, record.amount_, record.data_, 27u, rs, rs}))})).hex() << std::endl;
        }

    } else if (command == "federation") {
        static Selector<std::tuple<std::string>> getFederationAddress("getFederationAddress");
        const auto [federation] = co_await getFederationAddress.Call(*chain_, "latest", "0x0000000000000000000000000000000001000006", 90000);
        std::cout << federation << std::endl;

    } else if (command == "gas") {
        const auto [address] = Options<Address>(args);
        const auto [account] = co_await chain_->Get(co_await block(), address, nullptr);
        std::cout << account.balance_ / co_await chain_->Bid() << std::endl;

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

    } else if (command == "lottery0:look") {
        const auto [lottery, funder, signer] = Options<Address, Address, Address>(args);
        static Selector<std::tuple<uint128_t, uint128_t, uint256_t, Address, Bytes32, Bytes>, Address, Address> look("look");
        const auto [amount, escrow, unlock, verify, codehash, shared] = co_await look.Call(*chain_, "latest", lottery, 90000, funder, signer);
        std::cout << amount << " " << escrow << " " << unlock << std::endl;

    } else if (command == "lottery0:push") {
        const auto [lottery, signer, balance, escrow] = Options<Address, Address, uint128_t, uint128_t>(args);
        static Selector<void, Address, uint128_t, uint128_t> push("push");
        std::cout << (co_await executor_->Send(*chain_, {.gas = 175000}, lottery, 0, push(signer, balance + escrow, escrow))).hex() << std::endl;

    } else if (command == "lottery1:edit") {
        const auto [lottery, amount, signer, adjust, lock, retrieve] = Options<Address, uint256_t, Address, checked_int256_t, checked_int256_t, uint256_t>(args);
        static Selector<void, Address, checked_int256_t, checked_int256_t, uint256_t> edit("edit");
        std::cout << (co_await executor_->Send(*chain_, {}, lottery, amount, edit(signer, adjust, lock, retrieve))).hex() << std::endl;

    } else if (command == "lottery1:enrolled") {
        const auto [lottery, funder, recipient] = Options<Address, Address, Address>(args);
        static Selector<uint256_t, Address, Address> enrolled("enrolled");
        std::cout << co_await enrolled.Call(*chain_, "latest", lottery, 90000, funder, recipient) << std::endl;

    } else if (command == "lottery1:mark") {
        const auto [lottery, token, signer, marked] = Options<Address, Address, Address, uint64_t>(args);
        static Selector<void, Address, Address, uint64_t> mark("mark");
        std::cout << (co_await executor_->Send(*chain_, {}, lottery, 0, mark(token, signer, marked))).hex() << std::endl;

    } else if (command == "lottery1:read") {
        const auto [lottery, token, funder, signer] = Options<Address, Address, Address, Address>(args);
        static Selector<std::tuple<uint256_t, uint256_t>, Address, Address, Address> read("read");
        const auto [escrow_balance, unlock_warned] = co_await read.Call(*chain_, "latest", lottery, 90000, token, funder, signer);
        std::cout << uint128_t(escrow_balance) << " " << (escrow_balance >> 128) << " " << uint128_t(unlock_warned) << " " << uint64_t(unlock_warned >> 128) << " " << (unlock_warned >> 192) << std::endl;

    } else if (command == "nonce") {
        const auto [address] = Options<Address>(args);
        const auto [account] = co_await chain_->Get(co_await block(), address, nullptr);
        std::cout << account.nonce_ << std::endl;

    } else if (command == "number") {
        const auto [number] = Options<uint256_t>(args);
        std::cout << "0x" << std::hex << number << std::endl;

    } else if (command == "orchid:allow1") {
        const auto [seller, token, allowance, sender] = Options<Address, Address, uint256_t, Address>(args);
        static Selector<void, Address, uint256_t, std::vector<Address>> allow("allow");
        std::cout << (co_await executor_->Send(*chain_, {}, seller, 0, allow(token, allowance, {sender}))).hex() << std::endl;

    } else if (command == "orchid:allowed") {
        const auto [seller, token, sender] = Options<Address, Address, Address>(args);
        static Selector<uint256_t, Address, Address> allowed("allowed");
        std::cout << co_await allowed.Call(*chain_, "latest", seller, 90000, token, sender) << std::endl;

    } else if (command == "orchid:enroll1") {
        const auto [seller, cancel, recipient] = Options<Address, bool, Address>(args);
        static Selector<void, bool, std::vector<Address>> enroll("enroll");
        std::cout << (co_await executor_->Send(*chain_, {}, seller, 0, enroll(cancel, {recipient}))).hex() << std::endl;

    } else if (command == "orchid:hand") {
        const auto [seller, owner, manager] = Options<Address, Address, Address>(args);
        static Selector<void, Address, Address> hand("hand");
        std::cout << (co_await executor_->Send(*chain_, {}, seller, 0, hand(owner, manager))).hex() << std::endl;

    } else if (command == "orchid:giftv") {
        orc_assert(nonce_);
        const auto [seller] = Options<Address>(args);

        typedef std::tuple<Address, uint256_t, uint256_t> Gift;
        std::vector<Gift> gifts;
        uint256_t total(0);

        const auto csv(Load(std::to_string(uint64_t(*nonce_)) + ".csv"));
        for (auto line : Split(csv, {'\n'})) {
            if (line.empty() || line[0] == '#')
                continue;
            if (line[line.size() - 1] == '\r') {
                line -= 1;
                if (line.empty())
                    continue;
            }

            const auto comma0(Find(line, {','}));
            orc_assert(comma0);
            auto [recipient, rest] = Split(line, *comma0);

            const auto comma1(Find(rest, {','}));
            orc_assert(comma1);
            auto [amount$, escrow$] = Split(rest, *comma1);

            const uint256_t amount{std::string(amount$)};
            const uint256_t escrow{std::string(escrow$)};

            const auto combined(amount + escrow);
            orc_assert(combined >= escrow);

            const auto &gift(gifts.emplace_back(std::string(recipient), combined, escrow));
            std::cout << "gift " << seller << " " << std::get<0>(gift) << " " << std::get<1>(gift) << " " << std::get<2>(gift) << std::endl;
            total += std::get<1>(gift);
        }

        std::cout << "total = " << total << std::endl;

        static Selector<void, std::vector<Gift>> giftv("giftv");
        std::cout << (co_await executor_->Send(*chain_, {.nonce = nonce_}, seller, total, giftv(gifts))).hex() << std::endl;

    } else if (command == "orchid:move") {
        const auto [url, tls, gpg] = Options<Bytes, Bytes, Bytes>(args);
        static Selector<void, Bytes, Bytes, Bytes> move("move");
        std::cout << (co_await executor_->Send(*chain_, {.nonce = nonce_}, "0xEF7bc12e0F6B02fE2cb86Aa659FdC3EBB727E0eD", 0, move(url, tls, gpg))).hex() << std::endl;

    } else if (command == "orchid:read") {
        const auto [seller, token, signer] = Options<Address, Address, Address>(args);
        orc_assert(token == Address(0));
        static Selector<uint256_t, Address> read("read");
        const auto packed(co_await read.Call(*chain_, "latest", seller, 90000, signer));
        std::cout << std::dec << (packed >> 64) << " " << uint64_t(packed) << std::endl;

    } else if (command == "p2pkh") {
        // https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses
        const auto [key] = Options<Key>(args);
        std::cout << ToBase58Check(Tie('\x00', HashR(Hash2(ToCompressed(key))))) << std::endl;

    } else if (command == "p2wpkh") {
        // https://bitcointalk.org/index.php?topic=4992632.0
        const auto [key] = Options<Key>(args);
        std::cout << ToSegwit("bc", 0, HashR(Hash2(ToCompressed(key)))) << std::endl;

    } else if (command == "p2wsh") {
        // https://bitcointalk.org/index.php?topic=5227953
        const auto [key] = Options<Key>(args);
        std::cout << ToSegwit("bc", 0, Hash2(Tie(uint8_t(0x21), ToCompressed(key), uint8_t(0xac)))) << std::endl;

    } else if (command == "price") {
        const auto [symbol] = Options<std::string>(args);
        const auto ethereum(Make<Ethereum>(chain_));
        const auto currency(co_await Currency::New(5000, ethereum, base_, symbol));
        std::cout << currency.dollars_() << std::endl;

    } else if (command == "read") {
        const auto [contract, slot] = Options<Address, uint256_t>(args);
        const auto [account, value] = co_await chain_->Get(co_await block(), contract, nullptr, slot);
        std::cout << "0x" << std::hex << value << std::endl;

    } else if (command == "receipt") {
        const auto [transaction] = Options<Bytes32>(args);
        for (;;) {
            const auto receipt(co_await (*chain_)("eth_getTransactionReceipt", {transaction}));
            if (receipt.isNull())
                continue;
            std::cout << receipt << std::endl;
            break;
        }

    } else if (command == "recover") {
        const auto [signature, message] = Options<Signature, Bytes>(args);
        std::cout << ToUncompressed(Recover(HashK(message), signature)).hex() << std::endl;

    } else if (command == "resolve") {
        const auto [name] = Options<std::string>(args);
        std::cout << co_await Resolve(*chain_, (co_await block()).height_, name) << std::endl;

    } else if (command == "rlp-decode") {
        const auto [data] = Options<Bytes>(args);
        Window window(data);
        const auto nested(Explode(window));
        std::cout << nested.json();
        if (!window.done())
            std::cout << " " << window << std::endl;
        std::cout << std::endl;

    } else if (command == "rlp-encode") {
        const auto [value] = Options<Any>(args);
        std::cout << Strung(Implode(Nested(value))).hex(true) << std::endl;

    } else if (command == "rlp-print") {
        const auto [data] = Options<Bytes>(args);
        Window window(data);
        const auto nested(Explode(window));
        std::cout << nested;
        if (!window.done())
            std::cout << " " << window << std::endl;
        std::cout << std::endl;

    } else if (command == "run") {
        const auto [code, recipient, amount, data] = Options<Bytes, std::optional<Address>, uint256_t, Bytes>(args);
        const auto contract(recipient ? *recipient : Address(Random<20>()));
        std::cout << Str(co_await chain_->Call("eth_call", {Multi{
            {"from", executor_->operator Address()},
            {"to", contract},
            {"gas", gas_},
            {"gasPrice", flags.bid_},
            {"value", amount},
            {"data", data},
        }, (co_await block()).height_, Multi{
            {executor_->operator Address().str(), Multi{{"balance", amount}}},
            {contract.str(), Multi{{"code", code}}},
        }})) << std::endl;

    } else if (command == "segwit") {
        const auto [prefix, version, key] = Options<std::string, std::optional<uint8_t>, Key>(args);
        std::cout << ToSegwit(prefix, version, HashR(Hash2(ToCompressed(key)))) << std::endl;

    } else if (command == "send") {
        const auto [recipient, amount, data] = Options<Address, uint256_t, Bytes>(args);
        std::cout << (co_await executor_->Send(*chain_, {.nonce = nonce_, .gas = gas_}, recipient, amount, data)).hex() << std::endl;

    } else if (command == "sign") {
        const auto [secret, message] = Options<Bytes32, Bytes>(args);
        std::cout << Sign(secret, HashK(message)).operator Brick<65>().hex() << std::endl;

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

    } else if (command == "slot") {
        auto [height, address, slot] = Options<uint64_t, Address, uint256_t>(args);
        std::cout << Str(co_await chain_->Call("eth_getStorageAt", {address, slot, height})) << std::endl;

    } else if (command == "slot-ex") {
        auto [height, address, slot] = Options<uint64_t, Address, uint256_t>(args);
        std::cout << Str(co_await chain_->Call("eth_call", {Multi{
            {"from", "0x0000000000000000000000000000000000000000"},
            {"to", address},
            {"gas", uint64_t(90000)},
            {"data", Number<uint256_t>(slot)},
        }, height, Multi{{address.str(), Multi{{"code", "0x6000355460005260206000f3"}}}}})) << std::endl;

    } else if (command == "state") {
        const auto [height] = Options<uint64_t>(args);
        co_await ScanState(chain_, height);

    } else if (command == "storage") {
        const auto [height, address] = Options<uint64_t, Address>(args);
        co_await ScanStorage(chain_, height, address);

    } else if (command == "submit") {
        const auto [raw] = Options<Bytes>(args);
        std::cout << (co_await chain_->Send("eth_sendRawTransaction", {raw})).hex() << std::endl;

    } else if (command == "this") {
        Options<>(args);
        std::cout << executor_->operator Address() << std::endl;

    } else if (command == "timestamp") {
        Options<>(args);
        std::cout << Timestamp() << std::endl;

    } else if (command == "transaction") {
        const auto [transaction] = Options<Bytes32>(args);
        std::cout << co_await (*chain_)("eth_getTransactionByHash", {transaction}) << std::endl;

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
            if (line.empty() || line[0] == '#')
                continue;
            if (line[line.size() - 1] == '\r') {
                line -= 1;
                if (line.empty())
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

    } else if (command == "uniswap2") {
        const auto [pool] = Options<Address>(args);
        std::cout << co_await Uniswap2(*chain_, pool, 1) << std::endl;

    } else if (command == "uniswap3") {
        const auto [pool] = Options<Address>(args);
        std::cout << co_await Uniswap3(*chain_, pool, 1) << std::endl;

    } else if (command == "unwrap") {
        const auto [token, amount] = Options<Address, uint256_t>(args);
        static Selector<void, uint256_t> withdraw("withdraw");
        std::cout << (co_await executor_->Send(*chain_, {.nonce = nonce_, .gas = gas_}, token, amount, withdraw(amount))).hex() << std::endl;

    } else if (command == "value") {
        const auto [address] = Options<Address>(args);
        const auto [account] = co_await chain_->Get(co_await block(), address, nullptr);
        std::cout << Float(account.balance_) * co_await Binance(*base_, currency_ + "USDT", Ten18) << std::endl;

    } else if (command == "verify") {
        auto [height] = Options<uint64_t>(args);
        do {
            co_await chain_->Header(height);
            if (height % 1000 == 0)
                std::cerr << height << std::endl;
        } while (height-- != 0);

    } else if (command == "wif") {
        // https://en.bitcoin.it/wiki/Wallet_import_format
        // prefix with 0x80 for mainnet and 0xEF for testnet
        // suffix with 0x01 if this will be a compressed key
        const auto [data] = Options<Bytes>(args);
        std::cout << ToBase58Check(data) << std::endl;

    } else if (command == "wrap") {
        const auto [token, amount] = Options<Address, uint256_t>(args);
        static Selector<void> deposit("deposit");
        std::cout << (co_await executor_->Send(*chain_, {.nonce = nonce_, .gas = gas_}, token, 0, deposit())).hex() << std::endl;

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
