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
#include <vector>

#include "baton.hpp"
#include "coinbase.hpp"
#include "client.hpp"
#include "crypto.hpp"
#include "dns.hpp"
#include "json.hpp"
#include "jsonrpc.hpp"
#include "local.hpp"
#include "markup.hpp"
#include "network.hpp"
#include "remote.hpp"
#include "router.hpp"
#include "sleep.hpp"
#include "store.hpp"
#include "transport.hpp"

#include <boost/filesystem/string_file.hpp>
#include <boost/multiprecision/cpp_int.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include <rtc_base/logging.h>

using boost::multiprecision::uint256_t;

namespace orc {

namespace po = boost::program_options;

static const Float Ten18("1000000000000000000");
static const Float Two128(uint256_t(1) << 128);

struct Report {
    Float cost_;
    Float speed_;
    Host host_;
};

typedef std::tuple<Float, size_t> Measurement;

task<Measurement> Measure(Origin &origin) {
    co_await Sleep(1);
    const auto before(Monotonic());
    const auto test((co_await origin.Fetch("GET", {"https", "cache.saurik.com", "443", "/orchid/test-1MB.dat"}, {}, {})).ok());
    co_return Measurement{test.size() * 8 / Float(Monotonic() - before), test.size()};
}

task<Host> Find(Origin &origin) {
    // XXX: use STUN to do this instead of a Cydia endpoint
    co_return Parse((co_await origin.Fetch("GET", {"https", "cydia.saurik.com", "443", "/debug.json"}, {}, {})).ok())["host"].asString();
}

task<Report> Test(const S<Origin> &origin, std::string ovpn) {
    co_return co_await Using<BufferSink<Remote>>([&](BufferSink<Remote> &remote) -> task<Report> {
        co_await Connect(remote, origin, remote.Host(), std::move(ovpn), "", "");
        remote.Open();
        const auto [speed, size] = co_await Measure(remote);
        const auto host(co_await Find(remote));
        co_return Report{0, speed, host};
    });
}

task<Report> Test(const S<Origin> &origin, std::string name, const Float &price, Network &network, std::string provider, const Secret &secret, const Address &funder, const Address &seller) {
    std::cout << provider << " " << name << std::endl;

    co_return co_await Using<BufferSink<Remote>>([&](BufferSink<Remote> &remote) -> task<Report> {
        auto &client(*co_await network.Select(remote, origin, "untrusted.orch1d.eth", provider, "0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1", 1, secret, funder, seller));
        remote.Open();
        const auto [speed, size] = co_await Measure(remote);
        client.Update();
        const auto host(co_await Find(remote));
        const auto balance(client.Balance());
        const auto spent(client.Spent());
        const auto cost(Float(spent - balance) / size * (1024 * 1024 * 1024) * price / Two128);
        std::cout << name << ": DONE" << std::endl;
        co_return Report{cost, speed, host};
    });
}

struct State {
    uint256_t timestamp_;
    Float speed_;
    Report purevpn_;
    std::map<std::string, std::string> providers_;

    State(uint256_t timestamp) :
        timestamp_(std::move(timestamp))
    {
    }
};

std::shared_ptr<State> state_;

std::string Short(const Float &value) {
    std::ostringstream speed;
    speed << std::fixed << std::setprecision(4) << value;
    return speed.str();
}

// NOLINTNEXTLINE (modernize-avoid-c-arrays)
int Main(int argc, const char *const argv[]) {
    po::variables_map args;

    po::options_description options("command-line (only)");
    options.add_options()
        ("help", "produce help message")

        ("tls", po::value<std::string>(), "tls keys and chain (pkcs#12 encoded)")

        ("funder", po::value<std::string>())
        ("secret", po::value<std::string>())
        ("seller", po::value<std::string>()->default_value("0x0000000000000000000000000000000000000000"))
    ;

    po::store(po::parse_command_line(argc, argv, po::options_description()
        .add(options)
    ), args);

    po::notify(args);

    if (args.count("help") != 0) {
        std::cout << po::options_description()
            .add(options)
        << std::endl;
        return 0;
    }

    Initialize();

    const auto origin(Break<Local>());
    const std::string rpc("https://cloudflare-eth.com:443/");
    Endpoint endpoint(origin, Locator::Parse(rpc));

    const Address directory("0x918101FB64f467414e9a785aF9566ae69C3e22C5");
    const Address location("0xEF7bc12e0F6B02fE2cb86Aa659FdC3EBB727E0eD");

    const Address funder(args["funder"].as<std::string>());
    const Secret secret(Bless(args["secret"].as<std::string>()));
    const Address seller(args["seller"].as<std::string>());

    Spawn([&]() noexcept -> task<void> { try {
        const auto price(co_await Price(*origin, "OXT", "USD", Ten18));

        Network network(rpc, directory, location);

        std::string ovpn;
        boost::filesystem::load_string_file("PureVPN.ovpn", ovpn);
        const auto purevpn(co_await orc_value(co_return co_await, Test(origin, ovpn), "testing PureVPN"));

        for (;;) {
            std::vector<std::string> names;
            std::vector<task<Report>> tests;

            // NOLINTNEXTLINE (modernize-avoid-c-arrays)
            for (const auto &[provider, name] : (std::pair<const char *, const char *>[]) {
                {"0x605c12040426ddCc46B4FEAD4b18a30bEd201bD0", "Bloq"},
                {"0xe675657B3fBbe12748C7A130373B55c898E0Ea34", "BolehVPN"},
                {"0xf885C3812DE5AD7B3F7222fF4E4e4201c7c7Bd4f", "LiquidVPN"},
                //{"0x2b1ce95573ec1b927a90cb488db113b40eeb064a", "SaurikIT"},
                {"0x396bea12391ac32c9b12fdb6cffeca055db1d46d", "Tenta"},
                {"0x40e7cA02BA1672dDB1F90881A89145AC3AC5b569", "VPNSecure"},
            }) {
                names.emplace_back(name);
                tests.emplace_back(Test(origin, name, price, network, provider, secret, funder, seller));
            }

            const auto now(Timestamp());
            auto reports(co_await Parallel(std::move(tests)));
            auto state(std::make_shared<State>(now));

            try {
                state->speed_ = std::get<0>(co_await Measure(*origin));
            } catch (...) {
                state->speed_ = 0;
            }

            state->purevpn_ = purevpn;

            std::cout << std::endl;
            for (unsigned i(0); i != names.size(); ++i) {
                const auto name(names[i]);
                const auto text([&]() -> std::string { try {
                    const auto report(std::move(reports[i]).result());
                    std::ostringstream text;
                    text << std::fixed << std::setprecision(4);
                    text << "$" << report.cost_ << " " << std::setw(8) << report.speed_ << "Mbps   " << report.host_;
                    return text.str();
                } catch (const std::exception &error) {
                    std::string text(error.what());
                    boost::replace_all(text, "\r", "");
                    boost::replace_all(text, "\n", " || ");
                    return text;
                } }());

                state->providers_[name] = text;
                std::cout << "\e[32m[" << name << "] " << std::string(11 - name.size(), ' ') << text << "\e[0m" << std::endl;
            }

            std::atomic_store(&state_, state);
        }
    } orc_catch({}) });

    const Store store([&]() {
        std::string store;
        boost::filesystem::load_string_file(args["tls"].as<std::string>(), store);
        return store;
    }());

    Router router;

    router(http::verb::get, R"(/)", [&](Request request) -> task<Response> {
        const auto state(std::atomic_load(&state_));
        orc_assert(state);

        Markup body("Orchid Status");

        body << "T+" << (Timestamp() - state->timestamp_).str() << "s " << Short(state->speed_) << "Mbps\n";
        body << "\n";
        body << "PureVPN:     $-.----   " << Short(state->purevpn_.speed_) << "Mbps   " << state->purevpn_.host_.String() << "\n";
        body << "\n";
        for (const auto &provider : state->providers_)
            body << provider.first << ": " << std::string(11 - provider.first.size(), ' ') << provider.second << "\n";

        co_return Respond(request, http::status::ok, "text/html", body());
    });

    router(http::verb::get, R"(.*)", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, "text/plain", "");
    });

    router(http::verb::unknown, R"(.*)", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::method_not_allowed, "text/plain", "");
    });

    router.Run(boost::asio::ip::make_address("0.0.0.0"), 443, store.Key(), store.Chain());
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
