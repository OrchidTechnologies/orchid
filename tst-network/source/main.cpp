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


#include <iostream>
#include <regex>
#include <vector>

#include <cppcoro/async_mutex.hpp>

#include <boost/multiprecision/cpp_int.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include <rtc_base/logging.h>

#include "baton.hpp"
#include "boring.hpp"
#include "chainlink.hpp"
#include "chart.hpp"
#include "client.hpp"
#include "coinbase.hpp"
#include "crypto.hpp"
#include "dns.hpp"
#include "float.hpp"
#include "fiat.hpp"
#include "gauge.hpp"
#include "json.hpp"
#include "jsonrpc.hpp"
#include "load.hpp"
#include "local.hpp"
#include "markup.hpp"
#include "network.hpp"
#include "pile.hpp"
#include "remote.hpp"
#include "router.hpp"
#include "sequence.hpp"
#include "sleep.hpp"
#include "store.hpp"
#include "time.hpp"
#include "transport.hpp"
#include "uniswap.hpp"
#include "version.hpp"

using boost::multiprecision::uint256_t;

namespace orc {

namespace po = boost::program_options;

struct Global {
    uint64_t benefit_ = 0;
}; Locked<Global> global_;

struct Report {
    std::string stakee_;
    std::optional<Float> cost_;
    Float speed_;
    Host host_;
    Address recipient_;
    std::string version_;
};

typedef std::tuple<Float, size_t> Measurement;

task<Measurement> Measure(Origin &origin) {
    const auto before(Monotonic());

    size_t size(0);
    for (unsigned i(0); i != 3; ++i) {
        const auto test((co_await origin.Fetch("GET", {"https", "cache.saurik.com", "443", "/orchid/test-1MB.dat"}, {}, {})).ok());
        size += test.size();
    }

    co_return Measurement{size * 8 / Float(Monotonic() - before), size};
}

task<Host> Find(Origin &origin) {
    // XXX: use STUN to do this instead of a Cydia endpoint
    co_return Parse((co_await origin.Fetch("GET", {"https", "cydia.saurik.com", "443", "/debug.json"}, {}, {})).ok())["host"].asString();
}

task<std::string> Version(Origin &origin, const std::string &url) { try {
    orc_assert(!url.empty());
    orc_assert(url[url.size()-1] == '/');

    auto version((co_await origin.Fetch("GET", Locator::Parse(url + "version.txt"), {}, {})).ok());
    const auto line(version.find('\n'));
    if (line != std::string::npos)
        version = version.substr(0, line);

    static const std::regex re("[0-9a-f]{40}");
    orc_assert(std::regex_match(version, re));
    co_return version;
} orc_catch({ co_return ""; }) }

task<Report> TestOpenVPN(const S<Origin> &origin, std::string ovpn) {
    (co_await orc_optic)->Name("OpenVPN");
    co_return co_await Using<BufferSink<Remote>>([&](BufferSink<Remote> &remote) -> task<Report> {
        co_await Connect(remote, origin, remote.Host(), std::move(ovpn), "", "");
        remote.Open();
        const auto [speed, size] = co_await Measure(remote);
        const auto host(co_await Find(remote));
        co_return Report{"", std::nullopt, speed, host, ""};
    });
}

task<Report> TestWireGuard(const S<Origin> &origin, std::string config) {
    (co_await orc_optic)->Name("WireGuard");
    co_return co_await Using<BufferSink<Remote>>([&](BufferSink<Remote> &remote) -> task<Report> {
        co_await Guard(remote, origin, remote.Host(), std::move(config));
        remote.Open();
        const auto host(co_await Find(remote));
        const auto [speed, size] = co_await Measure(remote);
        co_return Report{"", std::nullopt, speed, host, ""};
    });
}

task<Report> TestOrchid(const S<Origin> &origin, std::string name, Network &network, const char *provider, const Secret &secret, const Address &funder) {
    (co_await orc_optic)->Name(provider);

    std::cout << provider << " " << name << std::endl;

    co_return co_await Using<BufferSink<Remote>>([&](BufferSink<Remote> &remote) -> task<Report> {
        auto &client(*co_await network.Select(remote, origin, "untrusted.orch1d.eth", provider, "0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1", 1, secret, funder, nullptr));
        remote.Open();

        const auto host(co_await Find(remote));
        const auto [speed, size] = co_await Measure(remote);

        client.Update();
        // XXX: support co_await on Update()
        co_await Sleep(1000);
        const auto spent(client.Spent());
        const auto balance(client.Balance());

        const auto benefit(client.Benefit());
        Log() << "BENEFIT " << std::dec << benefit << " " << name;
        const auto minimum([&]() {
            const auto global(global_());
            if (global->benefit_ == 0 || global->benefit_ > benefit)
                global->benefit_ = benefit;
            return global->benefit_;
        }());

        const auto recipient(client.Recipient());
        const auto version(co_await Version(*origin, client.URL()));
        const auto cost((spent - balance) / minimum * (1024 * 1024 * 1024));
        co_return Report{provider, cost, speed, host, recipient, version};
    });
}

struct Stake {
    uint256_t amount_;
    Maybe<std::string> url_;

    Stake(uint256_t amount, Maybe<std::string> url) :
        amount_(std::move(amount)),
        url_(std::move(url))
    {
    }
};

struct State {
    uint256_t timestamp_;
    Float speed_;
    std::map<std::string, Maybe<Report>> providers_;
    std::map<Address, Stake> stakes_;

    State(uint256_t timestamp) :
        timestamp_(std::move(timestamp))
    {
    }
};

std::shared_ptr<State> state_;

template <typename Code_>
task<void> Stakes(const Endpoint &endpoint, const Address &directory, const Block &block, const uint256_t &storage, const uint256_t &primary, const Code_ &code) {
    if (primary == 0)
        co_return;

    const auto stake(Hash(Tie(primary, uint256_t(0x2U))).num<uint256_t>());
    const auto [left, right, stakee, amount, delay] = co_await endpoint.Get(block, directory, storage, stake + 6, stake + 7, stake + 4, stake + 2, stake + 3);
    orc_assert(amount != 0);

    *co_await Parallel(
        Stakes(endpoint, directory, block, storage, left, code),
        Stakes(endpoint, directory, block, storage, right, code),
        code(uint160_t(stakee), amount, delay));
}

template <typename Code_>
task<void> Stakes(const Endpoint &endpoint, const Address &directory, const Code_ &code) {
    const auto number(co_await endpoint.Latest());
    const auto block(co_await endpoint.Header(number));
    const auto [account, root] = co_await endpoint.Get(block, directory, nullptr, 0x3U);
    co_await Stakes(endpoint, directory, block, account.storage_, root, code);
}

task<Float> Kraken(Origin &origin, const std::string &pair) {
    co_return Float(Parse((co_await origin.Fetch("GET", {"https", "api.kraken.com", "443", "/0/public/Ticker?pair=" + pair}, {}, {})).ok())["result"][pair]["c"][0].asString());
}

task<Fiat> Kraken(Origin &origin) {
    const auto [eth_usd, oxt_eth] = *co_await Parallel(Kraken(origin, "XETHZUSD"), Kraken(origin, "OXTETH"));
    co_return Fiat{eth_usd / Ten18, eth_usd * oxt_eth / Ten18};
}

void Print(std::ostream &body, const std::string &name, const Maybe<Report> &maybe) {
    body << " " << name << ": " << std::string(11 - name.size(), ' ');

    if (const auto error = std::get_if<0>(&maybe)) try {
        if (*error != nullptr)
            std::rethrow_exception(*error);
    } catch (const std::exception &error) {
        std::string what(error.what());
        boost::replace_all(what, "\r", "");
        boost::replace_all(what, "\n", " || ");
        body << what;
    } else if (const auto report = std::get_if<1>(&maybe)) {
        body << std::fixed << std::setprecision(4);
        body << "$";
        if (report->cost_)
            body << *report->cost_;
        else
            body << "-.----";
        body << " " << std::setw(8) << report->speed_ << "Mbps   " << report->host_;
        if (report->recipient_ != Address(0)) {
            std::ostringstream recipient;
            recipient << report->recipient_;
            body << "\n" << std::string(13, ' ') << recipient.str().substr(2);
        }
        if (!report->version_.empty())
            body << "\n" << std::string(13, ' ') << report->version_;
    } else orc_insist(false);

    body << "\n";
    body << "------------+---------+------------+-----------------\n";
}

int Main(int argc, const char *const argv[]) {
    std::vector<std::string> openvpns;
    std::vector<std::string> wireguards;

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

    { po::options_description group("external resources");
    group.add_options()
        ("rpc", po::value<std::string>()->default_value("http://127.0.0.1:8545/"), "ethereum json/rpc private API endpoint")
    ; options.add(group); }

    { po::options_description group("protocol testing");
    group.add_options()
        ("openvpn", po::value(&openvpns))
        ("wireguard", po::value(&wireguards))
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

    Initialize();

    const auto origin(Break<Local>());
    const std::string rpc(args["rpc"].as<std::string>());

    Endpoint endpoint(origin, Locator::Parse(rpc));

    const Address directory("0x918101FB64f467414e9a785aF9566ae69C3e22C5");
    const Address location("0xEF7bc12e0F6B02fE2cb86Aa659FdC3EBB727E0eD");
    Network network(rpc, directory, location, origin);

    const Address funder(args["funder"].as<std::string>());
    const Secret secret(Bless(args["secret"].as<std::string>()));

    const auto coinbase(Wait(CoinbaseFiat(60*1000, origin, "USD")));

    const auto kraken(Wait(Update(60*1000, [origin]() -> task<Fiat> {
        co_return co_await Kraken(*origin);
    }, "Kraken")));

    const auto uniswap(Wait(UniswapFiat(60*1000, endpoint)));

    // XXX: these are duplicated inside of Network (pass them in)
    const auto chainlink(Wait(ChainlinkFiat(60*1000, endpoint)));
    const auto gauge(Make<Gauge>(60*1000, origin));

    const auto account(Wait(Update(60*1000, [endpoint, funder, signer = Address(Commonize(secret))]() -> task<std::pair<uint128_t, uint128_t>> {
        static const Address lottery("0xb02396f06cc894834b7934ecf8c8e5ab5c1d12f1");
        static const Selector<std::tuple<uint128_t, uint128_t, uint256_t, Address, Bytes32, Bytes>, Address, Address> look("look");
        const auto [balance, escrow, unlock, verify, codehash, shared] = co_await look.Call(endpoint, "latest", lottery, uint256_t(90000), funder, signer);
        co_return std::make_pair(balance, escrow);
    }, "Account")));

    Spawn([&]() noexcept -> task<void> { for (;;) {
        Fiber::Report();
        co_await Sleep(10000);
    } }, "Report");

    Spawn([&]() noexcept -> task<void> { for (;;) try {
        const auto now(Timestamp());
        auto state(Make<State>(now));

        try {
            state->speed_ = std::get<0>(co_await Measure(*origin));
        } catch (...) {
            state->speed_ = 0;
        }

        *co_await Parallel([&]() -> task<void> { try {
            (co_await orc_optic)->Name("Stakes");

            cppcoro::async_mutex mutex;
            std::map<Address, uint256_t> stakes;

            co_await Stakes(endpoint, directory, [&](const Address &stakee, const uint256_t &amount, const uint256_t &delay) -> task<void> {
                std::cout << "DELAY " << stakee << " " << std::dec << delay << " " << std::dec << amount << std::endl;
                if (delay < 90*24*60*60)
                    co_return;
                const auto lock(co_await mutex.scoped_lock_async());
                stakes[stakee] += amount;
            });

            // XXX: Zip doesn't work if I inline this argument
            const auto urls(co_await Parallel(Map([&](const auto &stake) {
                return [&](Address provider) -> Task<std::string> {
                    static const Selector<std::tuple<uint256_t, Bytes, Bytes, Bytes>, Address> look_("look");
                    const auto &[set, url, tls, gpg] = co_await look_.Call(endpoint, "latest", location, 90000, provider);
                    orc_assert(set != 0);
                    co_return url.str();
                }(stake.first);
            }, stakes)));

            // XXX: why can't I move things out of this iterator? (note: I did use auto)
            for (const auto &stake : Zip(urls, stakes))
                orc_assert(state->stakes_.try_emplace(stake.get<1>().first, stake.get<1>().second, stake.get<0>()).second);
        } catch (...) {
        } }(), [&]() -> task<void> {
            (co_await orc_optic)->Name("Tests");

            std::vector<std::string> names;
            std::vector<task<Report>> tests;

            for (const auto &openvpn : openvpns) {
                names.emplace_back("OpenVPN");
                tests.emplace_back(TestOpenVPN(origin, Load(openvpn)));
            }

            for (const auto &wireguard : wireguards) {
                names.emplace_back("WireGuard");
                tests.emplace_back(TestWireGuard(origin, Load(wireguard)));
            }

            for (const auto &[provider, name] : (std::pair<const char *, const char *>[]) {
                {"0x605c12040426ddCc46B4FEAD4b18a30bEd201bD0", "Bloq"},
                {"0xe675657B3fBbe12748C7A130373B55c898E0Ea34", "BolehVPN"},
                {"0xf885C3812DE5AD7B3F7222fF4E4e4201c7c7Bd4f", "LiquidVPN"},
                //{"0xc654a58330b8659399067c309Be93659FbaCbEA6", "Orchid"},
                //{"0x2b1ce95573ec1b927a90cb488db113b40eeb064a", "SaurikIT"},
                {"0x396bea12391ac32c9b12fdb6cffeca055db1d46d", "Tenta"},
                {"0x40e7cA02BA1672dDB1F90881A89145AC3AC5b569", "VPNSecure"},
            }) {
                names.emplace_back(name);
                tests.emplace_back(TestOrchid(origin, name, network, provider, secret, funder));
            }

            auto reports(co_await Parallel(std::move(tests)));
            for (unsigned i(0); i != names.size(); ++i)
                state->providers_[names[i]] = std::move(reports[i]);
        }());

        std::atomic_store(&state_, state);
        co_await Sleep(1000);
    } orc_catch({ orc_insist(false); }) }, "Update");

    Router router;

    router(http::verb::get, R"(/)", [&](Request request) -> task<Response> {
        const auto state(std::atomic_load(&state_));
        orc_assert(state);

        Markup markup("Orchid Status");
        std::ostringstream body;

        const auto [balance, escrow] = (*account)();
        body << "T+" << std::dec << (Timestamp() - state->timestamp_) << "s " << std::fixed << std::setprecision(4) << state->speed_ << "Mbps " <<
            std::setprecision(1) << (Float(balance) / Ten18) << "/" << (Float(escrow) / Ten18) << "\n";
        body << "\n";

        { const auto fiat((*coinbase)()); body << "Coinbase:  $" << std::fixed << std::setprecision(3) << (fiat.eth_ * Ten18) << " $" << std::setprecision(5) << (fiat.oxt_ * Ten18) << "\n"; }
        { const auto fiat((*kraken)()); body << "Kraken:    $" << std::fixed << std::setprecision(3) << (fiat.eth_ * Ten18) << " $" << std::setprecision(5) << (fiat.oxt_ * Ten18) << "\n"; }
        { const auto fiat((*uniswap)()); body << "Uniswap:   $" << std::fixed << std::setprecision(3) << (fiat.eth_ * Ten18) << " $" << std::setprecision(5) << (fiat.oxt_ * Ten18) << "\n"; }
        { const auto fiat((*chainlink)()); body << "Chainlink: $" << std::fixed << std::setprecision(3) << (fiat.eth_ * Ten18) << " $" << std::setprecision(5) << (fiat.oxt_ * Ten18) << "\n"; }
        body << "\n";

        for (const auto &[name, provider] : state->providers_)
            Print(body, name, provider);
        body << "\n";

        const auto price(gauge->Price());
        const auto fiat((*coinbase)());
        const auto overhead(Float(price) * fiat.eth_);

        body << "Cost: ";
        body << "v0= $" << std::fixed << std::setprecision(2) << (overhead * 100000) << " || ";
        body << "v1= $" << std::fixed << std::setprecision(2) << (overhead * 85000) << " || ";
        body << "v2= $" << std::fixed << std::setprecision(2) << (overhead * 300000) << " (ish)\n";
        body << "\n";

        const auto gas(100000);
        const auto coefficient((overhead * gas) / (fiat.oxt_ * Ten18));

        const auto bound((coefficient / ((1-0.80) / 2)).convert_to<float>());
        const auto zero((coefficient / ((1-0.00) / 2)).convert_to<float>());

        Chart(body, 49, 21, [&](float x) -> float {
            return x * (bound - zero) + zero;
        }, [&](float escrow) -> float {
            return (1 - coefficient / (escrow / 2)).convert_to<float>();
        }, [&](std::ostream &out, float x) {
            out << std::fixed << std::setprecision(0) << std::setw(3) << x * 100 << '%';
        });

        body << "\n";

        for (const auto &[stakee, stake] : state->stakes_) {
            body << Address(stakee) << " " << std::dec << std::fixed << std::setprecision(3) << std::setw(10) << (Float(stake.amount_) / Ten18) << "\n";

            body << "  ";

            if (const auto error = std::get_if<0>(&stake.url_)) try {
                std::rethrow_exception(*error);
            } catch (const std::exception &error) {
                std::string what(error.what());
                boost::replace_all(what, "\r", "");
                boost::replace_all(what, "\n", " || ");
                body << what;
            } else if (const auto url = std::get_if<1>(&stake.url_)) {
                body << *url;
            } else orc_insist(false);

            body << "\n";
        }

        markup << body.str();
        co_return Respond(request, http::status::ok, "text/html", markup());
    });

    const auto oracle([&]() {
        const auto state(std::atomic_load(&state_));
        orc_assert(state);

        Pile<Float, uint256_t> costs;
        for (const auto &[name, provider] : state->providers_)
            if (const auto report = std::get_if<1>(&provider)) {
                if (!report->cost_)
                    continue;
                const auto stake(state->stakes_.find(report->stakee_));
                orc_assert(stake != state->stakes_.end());
                costs(*report->cost_, stake->second.amount_);
            }

        return costs.med();
    });

    router(http::verb::get, R"(/chainlink/0)", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, "text/plain", oracle().str());
    });

    router(http::verb::post, R"(/chainlink/1)", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, "application/json", Unparse(Multi{
            {"jobRunID", Parse(request.body())["id"].asString()},
            {"data", Multi{{"price", oracle().str()}}},
        }));
    });

    router(http::verb::get, "/version.txt", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, "text/plain", std::string(VersionData, VersionSize));
    });

    const Store store(Load(args["tls"].as<std::string>()));
    router.Run(boost::asio::ip::make_address("0.0.0.0"), args["port"].as<uint16_t>(), store.Key(), store.Chain());
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
