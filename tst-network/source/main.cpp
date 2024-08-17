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


#include <iostream>
#include <regex>
#include <vector>

#include <cppcoro/async_mutex.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include <rtc_base/logging.h>
#include <system_wrappers/include/field_trial.h>

#include <jinja2cpp/binding/boost_json.h>
#include <jinja2cpp/reflected_value.h>
#include <jinja2cpp/template.h>
#include <jinja2cpp/template_env.h>

#include "baton.hpp"
#include "client0.hpp"
#include "client1.hpp"
#include "crypto.hpp"
#include "currency.hpp"
#include "float.hpp"
#include "fiat.hpp"
#include "format.hpp"
#include "jsonrpc.hpp"
#include "load.hpp"
#include "local.hpp"
#include "network.hpp"
#include "notation.hpp"
#include "pile.hpp"
#include "remote.hpp"
#include "sequence.hpp"
#include "site.hpp"
#include "sleep.hpp"
#include "store.hpp"
#include "time.hpp"
#include "updater.hpp"
#include "version.hpp"

using boost::multiprecision::uint256_t;

namespace orc {

namespace po = boost::program_options;

struct Global {
    uint64_t benefit_ = 0;
// NOLINTNEXTLINE(cppcoreguidelines-avoid-non-const-global-variables)
}; Locked<Global> global_;

struct Report {
    Locator locator_;
    Float cost_;
    Float speed_;
    Host host_;
    Address recipient_;
    std::string version_;
};

typedef std::tuple<Float, size_t> Measurement;

task<Measurement> Measure(Base &base) {
    const auto before(Monotonic());

    size_t size(0);
    for (unsigned i(0); i != 3; ++i) {
        const auto test((co_await base.Fetch("GET", {{"https", "cache.saurik.com", "443"}, "/orchid/test-1MB.dat"}, {}, {})).ok());
        size += test.size();
    }

    co_return Measurement{size * 8 / Float(Monotonic() - before), size};
}

task<Host> Find(Base &base) {
    // XXX: use STUN to do this instead of a Cydia endpoint
    co_return Str(Parse((co_await base.Fetch("GET", {{"https", "cydia.saurik.com", "443"}, "/debug.json"}, {}, {})).ok()).at("host"));
}

task<std::string> Version(Base &base, const Locator &url) { try {
    auto version((co_await base.Fetch("GET", url + "version.txt", {}, {})).ok());
    const auto line(version.find('\n'));
    if (line != std::string::npos)
        version = version.substr(0, line);

    static const std::regex re("[0-9a-f]{40}");
    orc_assert(std::regex_match(version, re));
    co_return version;
} orc_catch({ co_return ""; }) }

task<Report> TestOrchid(const S<Base> &base, const S<Network> &network, const Address &address, std::function<task<Client &> (BufferSink<Remote> &)> code) {
    const auto name(address.str());
    (co_await orc_optic)->Name(name.c_str());

    co_return co_await Using<BufferSink<Remote>>([&](BufferSink<Remote> &remote) -> task<Report> {
        const auto provider(co_await network->Select("untrusted.orch1d.eth", address));
        Client &client(co_await code(remote));
        co_await client.Open(provider, base);
        remote.Open();

        const auto host(co_await Find(remote));
        const auto [speed, size] = co_await Measure(remote);

        client.Update();
        // XXX: support co_await on Update()
        co_await Sleep(1000);
        const auto spent(client.Spent());
        const auto balance(client.Balance());

        const auto benefit(client.Benefit());
        const auto minimum([&]() {
            const auto global(global_());
            if (global->benefit_ == 0 || global->benefit_ > benefit)
                global->benefit_ = benefit;
            return global->benefit_;
        }());

        const auto recipient(client.Recipient());
        const auto version(co_await Version(*base, provider.locator_));
        const auto cost((spent - balance) / minimum * (1024 * 1024 * 1024));
        co_return Report{provider.locator_, cost, speed, host, recipient, version};
    });
}

struct Stakee {
    uint256_t staked_;
    Address address_;
    Maybe<std::string> locator_;
    Maybe<Report> report_;
};

bool operator <(const Stakee &lhs, const Stakee &rhs) {
    return lhs.staked_ > rhs.staked_;
}

struct State {
    uint256_t timestamp_;
    Float speed_;

    uint256_t staked_;
    std::map<Address, Stake> stakes_;
    std::vector<Stakee> stakees_;

    State(uint256_t timestamp) :
        timestamp_(std::move(timestamp))
    {
    }
};

// NOLINTNEXTLINE(cppcoreguidelines-avoid-non-const-global-variables)
std::shared_ptr<State> state_;

template <typename Type_, typename Value_>
auto &At(Type_ &&type, const Value_ &value) {
    auto i(type.find(value));
    orc_assert(i != type.end());
    return *i;
}

int Main(int argc, const char *const argv[]) {
    std::vector<std::string> chains;

    po::variables_map args;

    po::options_description group("general command line");
    group.add_options()
        ("help", "produce help message")
    ;

    po::options_description options;

    { po::options_description group("network endpoint");
    group.add_options()
        ("port", po::value<uint16_t>()->default_value(443), "port to advertise on blockchain")
        ("tls", po::value<std::string>(), "tls keys and chain (pkcs#12 encoded)")
    ; options.add(group); }

    { po::options_description group("orchid account");
    group.add_options()
        ("funder", po::value<std::string>())
        ("secret", po::value<std::string>())
    ; options.add(group); }

    { po::options_description group("evm json/rpc server (required)");
    group.add_options()
        ("chain", po::value<std::vector<std::string>>(&chains), "like 1,ETH,https://cloudflare-eth.com/")
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
        return 0;
    }

    const unsigned milliseconds(60*1000);
    const S<Base> base(Break<Local>());

    const auto ethereum(Wait(Ethereum::New(base, chains)));
    const auto markets(Wait(Market::All(milliseconds, ethereum, base, chains)));

    const Address directory("0x918101FB64f467414e9a785aF9566ae69C3e22C5");
    const Address location("0xEF7bc12e0F6B02fE2cb86Aa659FdC3EBB727E0eD");
    const auto network(Break<Network>(ethereum, directory, location));

    static const Address lottery0("0xb02396f06cc894834b7934ecf8c8e5ab5c1d12f1");
    static const Address lottery1("0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82");

    const Address funder(args["funder"].as<std::string>());
    const auto secret(Bless<Secret>(args["secret"].as<std::string>()));

    const auto oracle(Wait(Oracle(milliseconds, ethereum)));
    const auto oxt(Wait(Token::OXT(milliseconds, ethereum)));


    const auto account(Wait(Opened(Updating(milliseconds, [ethereum, funder, signer = Address(Derive(secret))]() -> task<std::pair<uint128_t, uint128_t>> {
        static const Selector<std::tuple<uint128_t, uint128_t, uint256_t, Address, Bytes32, Bytes>, Address, Address> look("look");
        const auto [balance, escrow, unlock, verify, codehash, shared] = co_await look.Call(*ethereum, "latest", lottery0, uint256_t(90000), funder, signer);
        co_return std::make_pair(balance, escrow);
    }, "Account"))));

    Spawn([&]() noexcept -> task<void> { for (;;) {
        Fiber::Report();
        co_await Sleep(10000);
    } }, "Report");

    Spawn([&]() noexcept -> task<void> { for (;;) try {
        const auto now(Timestamp());
        auto state(Make<State>(now));

        try {
            state->speed_ = std::get<0>(co_await Measure(*base));
        } catch (...) {
            state->speed_ = 0;
        }

        state->stakes_ = co_await network->Scan();

        std::vector<task<Report>> tests;

        for (const auto &[provider, stake] : state->stakes_) {
            state->staked_ += stake.amount_;
            tests.emplace_back(TestOrchid(base, network, provider, [&](BufferSink<Remote> &remote) -> task<Client &> {
                co_return co_await Client0::Wire(remote, oracle, oxt, lottery0, secret, funder);
                //co_return co_await Client1::Wire(remote, oracle, At(markets, 43114), lottery1, secret, funder);
            }));
        }

        auto reports(co_await Parallel(std::move(tests)));
        // XXX: something about the const correctness here is wrong
        for (const auto &[stake, report] : Zip(state->stakes_, reports))
            state->stakees_.emplace_back(stake.second.amount_, stake.first, stake.second.url_, std::move(report));

        std::sort(state->stakees_.begin(), state->stakees_.end());

        std::atomic_store(&state_, state);
        co_await Sleep(1000);
    } orc_catch({ orc_insist(false); }) }, "Update");

    Site site;

    jinja2::TemplateEnv env;

    // XXX: in "production", use MemoryFileSystem
    jinja2::RealFileSystem fs;
    env.AddFilesystemHandler("", fs);

    site(http::verb::get, "/", [&](Request request) -> task<Response> {
        const auto state(std::atomic_load(&state_));
        orc_assert(state);

        const auto [balance, escrow] = (*account)();
        orc_assert(balance != 0);

        auto tpl(env.LoadTemplate("source/index.j2").value());

        Array providers;
        for (const auto &stakee : state->stakees_) {
            Object params;
            params["stakee"] = stakee.address_.str();
            params["staked"] = double(stakee.staked_);

            try {
                params["locator"] = *stakee.locator_;

                const auto &report(*stakee.report_);
                params["cost"] = double(report.cost_);
                params["speed"] = double(report.speed_);
                params["host"] = std::string(report.host_);
                params["recipient"] = report.recipient_.str();
                params["version"] = report.version_;
            } catch (const std::exception &error) {
                params["error"] = error.what();
            }

            providers.emplace_back(std::move(params));
        }

        auto body(tpl.RenderAsString({
            {"staked", double(state->staked_)},
            {"providers", jinja2::Reflect(Any(providers))},
        }).value());

        co_return Respond(request, http::status::ok, {
            {"content-type", "text/html"},
        }, std::move(body));
    });

    const auto median([&]() {
        const auto state(std::atomic_load(&state_));
        orc_assert(state);

        Pile<Float, uint256_t> costs;
        for (const auto &stakee : state->stakees_)
            if (const auto report = std::get_if<1>(&stakee.report_))
                if (report->cost_ != 0)
                    if (const auto stake(state->stakes_.find(stakee.address_)); stake != state->stakes_.end())
                        costs(report->cost_, stake->second.amount_);
        return costs.med();
    });

    site(http::verb::get, "/chainlink/0", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, {
            {"content-type", "text/plain"},
        }, [&]() -> std::string { try {
            return median().str();
        } catch (const std::exception &error) {
            return "0.06";
        } }());
    });

    site(http::verb::post, "/chainlink/1", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, {
            {"content-type", "application/json"},
        }, UnparseO(Multi{
            {"jobRunID", Str(Parse(request.body()).at("id"))},
            // NOLINTNEXTLINE(clang-analyzer-core.StackAddressEscape)
            {"data", Multi{{"price", median().str()}}},
        }));
    });

    site(http::verb::get, "/version.txt", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, {
            {"content-type", "text/plain"},
        }, std::string(VersionData, VersionSize));
    });

    const Store store(Load(args["tls"].as<std::string>()));
    site.Run(boost::asio::ip::make_address("0.0.0.0"), args["port"].as<uint16_t>(), store.Key(), store.Certificates());
    Thread().join();
    return 0;
}

}

int main(int argc, const char *const argv[]) { try {
    return orc::Main(argc, argv);
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    return 1;
} }
