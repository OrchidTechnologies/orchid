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

#include "baton.hpp"
#include "boring.hpp"
#include "chainlink.hpp"
#include "chart.hpp"
#include "client0.hpp"
#include "client1.hpp"
#include "crypto.hpp"
#include "currency.hpp"
#include "dns.hpp"
#include "float.hpp"
#include "fiat.hpp"
#include "huobi.hpp"
#include "jsonrpc.hpp"
#include "load.hpp"
#include "local.hpp"
#include "markup.hpp"
#include "network.hpp"
#include "notation.hpp"
#include "oracle.hpp"
#include "pile.hpp"
#include "pricing.hpp"
#include "remote.hpp"
#include "site.hpp"
#include "sleep.hpp"
#include "store.hpp"
#include "time.hpp"
#include "transport.hpp"
#include "uniswap.hpp"
#include "updater.hpp"
#include "version.hpp"

using boost::multiprecision::uint256_t;

namespace orc {

namespace po = boost::program_options;

struct Global {
    uint64_t benefit_ = 0;
}; Locked<Global> global_;

struct Report {
    Address stakee_;
    std::optional<Float> cost_;
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

task<Report> TestOpenVPN(const S<Base> &base, std::string ovpn) {
    (co_await orc_optic)->Name("OpenVPN");
    co_return co_await Using<BufferSink<Remote>>([&](BufferSink<Remote> &remote) -> task<Report> {
        co_await Connect(remote, base, remote.Host().operator uint32_t(), std::move(ovpn), "", "");
        remote.Open();
        const auto [speed, size] = co_await Measure(remote);
        const auto host(co_await Find(remote));
        co_return Report{{}, std::nullopt, speed, host, {}, ""};
    });
}

task<Report> TestWireGuard(const S<Base> &base, std::string config) {
    (co_await orc_optic)->Name("WireGuard");
    co_return co_await Using<BufferSink<Remote>>([&](BufferSink<Remote> &remote) -> task<Report> {
        co_await Guard(remote, base, remote.Host().operator uint32_t(), std::move(config));
        remote.Open();
        const auto host(co_await Find(remote));
        const auto [speed, size] = co_await Measure(remote);
        co_return Report{{}, std::nullopt, speed, host, {}, ""};
    });
}

task<Report> TestOrchid(const S<Base> &base, std::string name, const S<Network> &network, const char *address, std::function<task<Client &> (BufferSink<Remote> &)> code) {
    (co_await orc_optic)->Name(address);

    std::cout << address << " " << name << std::endl;

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
        Log() << "BENEFIT " << std::dec << benefit << " " << name;
        const auto minimum([&]() {
            const auto global(global_());
            if (global->benefit_ == 0 || global->benefit_ > benefit)
                global->benefit_ = benefit;
            return global->benefit_;
        }());

        const auto recipient(client.Recipient());
        const auto version(co_await Version(*base, provider.locator_));
        const auto cost((spent - balance) / minimum * (1024 * 1024 * 1024));
        co_return Report{provider.address_, cost, speed, host, recipient, version};
    });
}

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

void Print(std::ostream &body, const std::string &name, const Maybe<Report> &maybe) {
    body << " " << name << ": " << std::string(11 - name.size(), ' ');

    if (const auto error = std::get_if<0>(&maybe)) try {
        if (*error != nullptr)
            std::rethrow_exception(*error);
    } catch (const std::exception &error) {
        std::string what(error.what());
        boost::replace_all(what, "\r", "");
        boost::replace_all(what, "\n", " || ");
        body << Escape(std::move(what));
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
            body << "\n" << std::string(13, ' ') << "<a href='https://github.com/OrchidTechnologies/orchid/commit/" << report->version_ << "'>" << report->version_ << "</a>";
    } else orc_insist(false);

    body << "\n";
    body << "------------+---------+------------+-----------------\n";
}

template <typename Type_, typename Value_>
auto &At(Type_ &&type, const Value_ &value) {
    auto i(type.find(value));
    orc_assert(i != type.end());
    return *i;
}

int Main(int argc, const char *const argv[]) {
    std::vector<std::string> chains;

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

    { po::options_description group("evm json/rpc server (required)");
    group.add_options()
        ("chain", po::value<std::vector<std::string>>(&chains), "like 1,ETH,https://cloudflare-eth.com/")
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
    //webrtc::field_trial::InitFieldTrialsFromString("WebRTC-DataChannel-Dcsctp/Enabled/");

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

    // prices {{{
    std::map<std::string, S<Updated<std::pair<Float, Float>>>> prices;

    prices.try_emplace("Coinbase", Wait(Opened(Updating(milliseconds, [base]() -> task<std::pair<Float, Float>> {
        co_return *co_await Parallel(Coinbase(*base, "ETH-USD"), Coinbase(*base, "OXT-USD"));
    }, "Coinbase"))));

    prices.try_emplace("Binance", Wait(Opened(Updating(milliseconds, [base]() -> task<std::pair<Float, Float>> {
        co_return *co_await Parallel(Binance(*base, "ETHUSDT"), Binance(*base, "OXTUSDT"));
    }, "Binance"))));

    prices.try_emplace("Kraken", Wait(Opened(Updating(milliseconds, [base]() -> task<std::pair<Float, Float>> {
        const auto [eth, oxt] = *co_await Parallel(Kraken(*base, "XETHZUSD"), Kraken(*base, "OXTETH", 1));
        co_return std::make_tuple(eth, eth * oxt);
    }, "Kraken"))));

    prices.try_emplace("Huobi", Wait(Opened(Updating(milliseconds, [base]() -> task<std::pair<Float, Float>> {
        co_return *co_await Parallel(Huobi(*base, "ethusdt"), Huobi(*base, "oxtusdt"));
    }, "Huobi"))));

    prices.try_emplace("Uniswap2", Wait(Opened(Updating(milliseconds, [ethereum]() -> task<std::pair<Float, Float>> {
        const auto [eth, oxt] = *co_await Parallel(Uniswap2(*ethereum, Uniswap2USDCETH, Ten6), Uniswap2(*ethereum, Uniswap2OXTETH, 1));
        co_return std::make_tuple(eth, eth / oxt);
    }, "Uniswap2"))));

    prices.try_emplace("Uniswap3", Wait(Opened(Updating(milliseconds, [ethereum]() -> task<std::pair<Float, Float>> {
        const auto [wei, oxt] = *co_await Parallel(Uniswap3(*ethereum, Uniswap3USDCETH, Ten6), Uniswap3(*ethereum, Uniswap3OXTETH, 1));
        const auto eth(1 / wei / Ten18);
        co_return std::make_tuple(eth, eth * oxt);
    }, "Uniswap3"))));

    prices.try_emplace("Chainlink", Wait(Opened(Updating(milliseconds, [ethereum]() -> task<std::pair<Float, Float>> {
        co_return *co_await Parallel(Chainlink(*ethereum, ChainlinkETHUSD, 0, Ten8 * Ten18), Chainlink(*ethereum, ChainlinkOXTUSD, 0, Ten8 * Ten18));
    }, "Chainlink"))));
    // }}}


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

        *co_await Parallel([&]() -> task<void> { try {
            (co_await orc_optic)->Name("Stakes");
            state->stakes_ = co_await network->Scan();
        } catch (...) {
        } }(), [&]() -> task<void> {
            (co_await orc_optic)->Name("Tests");

            std::vector<std::string> names;
            std::vector<task<Report>> tests;

            for (const auto &openvpn : openvpns) {
                names.emplace_back("OpenVPN");
                tests.emplace_back(TestOpenVPN(base, Load(openvpn)));
            }

            for (const auto &wireguard : wireguards) {
                names.emplace_back("WireGuard");
                tests.emplace_back(TestWireGuard(base, Load(wireguard)));
            }

            for (const auto &[provider, name] : (std::pair<const char *, const char *>[]) {
                {"0x605c12040426ddCc46B4FEAD4b18a30bEd201bD0", "Bloq"},
                {"0xe675657B3fBbe12748C7A130373B55c898E0Ea34", "BolehVPN"},
                //{"0xc654a58330b8659399067c309Be93659FbaCbEA6", "Orchid"},
                {"0x69A4Ed2024bc7056fBA8E18cEfc2c40932B923E3", "PIA"},
                {"0x2b1ce95573ec1b927a90cb488db113b40eeb064a", "SaurikIT"},
                {"0x396bea12391ac32c9b12fdb6cffeca055db1d46d", "Tenta"},
                {"0x40e7cA02BA1672dDB1F90881A89145AC3AC5b569", "VPNSecure"},
            }) {
                names.emplace_back(name);
                tests.emplace_back(TestOrchid(base, name, network, provider, [&](BufferSink<Remote> &remote) -> task<Client &> {
                    co_return co_await Client0::Wire(remote, oracle, oxt, lottery0, secret, funder);
                    //co_return co_await Client1::Wire(remote, oracle, At(markets, 43114), lottery1, secret, funder);
                }));
            }

            auto reports(co_await Parallel(std::move(tests)));
            for (unsigned i(0); i != names.size(); ++i)
                state->providers_[names[i]] = std::move(reports[i]);
        }());

        std::atomic_store(&state_, state);
        co_await Sleep(1000);
    } orc_catch({ orc_insist(false); }) }, "Update");

    Site site;

    site(http::verb::get, "/", [&](Request request) -> task<Response> {
        const auto state(std::atomic_load(&state_));
        orc_assert(state);

        Markup markup("Orchid Status");
        std::ostringstream body;

        const auto [balance, escrow] = (*account)();
        body << "T+" << std::dec << (Timestamp() - state->timestamp_) << "s " << std::fixed << std::setprecision(4) << state->speed_ << "Mbps " <<
            std::setprecision(1) << (Float(balance) / Ten18) << "/" << (Float(escrow) / Ten18) << "\n";
        body << "\n";

        for (const auto &[name, price] : prices) {
            const auto [eth, oxt] = (*price)();
            body << name << std::string(9 - name.size(), ' ') << ": $" << std::fixed << std::setprecision(3) << (eth * Ten18) << " $" << std::setprecision(5) << (oxt * Ten18);
            body << "\n";
        }
        body << "\n";

        for (const auto &[name, provider] : state->providers_)
            Print(body, name, provider);
        body << "\n";

        const auto price((*oxt.market_.bid_)());
        const auto overhead(Float(price) * oxt.market_.currency_.dollars_());

        body << "Cost: ";
        body << "v0= $" << std::fixed << std::setprecision(2) << (overhead * 83328) << " || ";
        body << "v1= $" << std::fixed << std::setprecision(2) << (overhead * 66327) << " || ";
        body << "v2= $" << std::fixed << std::setprecision(2) << (overhead * 300000) << " (ish)";
        body << "\n";

        body << "      ";
        body << "rf= $" << std::fixed << std::setprecision(2) << (overhead * 57654) << " || ";
        body << "1k= $" << std::fixed << std::setprecision(2) << (overhead * 1000) << " || ";
        body << "$1= " << std::fixed << uint64_t(1 / overhead);
        body << "\n";

        body << "\n";

        body << price << std::endl;
        body << "\n";

        body << "\n";

        const auto gas(84000);
        const auto coefficient((overhead * gas) / (oxt.currency_.dollars_() * Ten18));

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
                body << Escape(std::move(what));
            } else if (const auto url = std::get_if<1>(&stake.url_)) {
                body << Escape(*url);
            } else orc_insist(false);

            body << "\n";
        }

        markup << body.str();
        co_return Respond(request, http::status::ok, {
            {"content-type", "text/html"},
        }, markup());
    });

    const auto median([&]() {
        const auto state(std::atomic_load(&state_));
        orc_assert(state);

        Pile<Float, uint256_t> costs;
        for (const auto &[name, provider] : state->providers_)
            if (const auto report = std::get_if<1>(&provider))
                if (report->cost_ && *report->cost_ != 0)
                    if (const auto stake(state->stakes_.find(report->stakee_)); stake != state->stakes_.end())
                        costs(*report->cost_, stake->second.amount_);
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
