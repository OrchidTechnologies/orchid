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

#include "baton.hpp"
#include "cairo.hpp"
#include "chain.hpp"
#include "crypto.hpp"
#include "float.hpp"
#include "jsonrpc.hpp"
#include "load.hpp"
#include "local.hpp"
#include "markup.hpp"
#include "notation.hpp"
#include "parallel.hpp"
#include "pile.hpp"
#include "remote.hpp"
#include "sequence.hpp"
#include "site.hpp"
#include "sleep.hpp"
#include "store.hpp"
#include "time.hpp"
#include "transport.hpp"
#include "version.hpp"

using boost::multiprecision::uint256_t;

namespace orc {

namespace po = boost::program_options;

std::string Human(unsigned seconds) {
    unsigned minutes(seconds / 60);
    seconds %= 60;
    unsigned hours(minutes / 60);
    minutes %= 60;
    unsigned days(hours / 24);
    hours %= 24;
    std::ostringstream human;
    if (days != 0)
        human << days << "d";
    if (hours != 0)
        human << hours << "h";
    if (minutes != 0)
        human << minutes << "m";
    if (seconds != 0)
        human << seconds << "s";
    return human.str();
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

    { po::options_description group("external resources");
    group.add_options()
        ("rpc", po::value<std::string>()->default_value("http://127.0.0.1:8545/"), "ethereum json/rpc private API endpoint")
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

    const S<Base> base(Break<Local>());
    const std::string rpc(args["rpc"].as<std::string>());
    const auto chain(Wait(Chain::New({rpc, base}, {})));

    const auto gauge(Make<Gauge>(60*1000, base));

    std::set<Address> miners{
        "0x155296080f5889b9a4c328bcc533f928efd02a05",
        "0x4eF5C587e53c66cdfBC6588E29DCb100A5859263",
        "0x5a0b54d5dc17e0aadc383d2db43b0a0d3e029c4c",
        "0x7bd36fd6fc927952b87d90f1c28ed358bc342039",
        "0x8fD00f170FDf3772C5ebdCD90bF257316c69BA45",
        "0xdeD3bb4E6a3F0ADb5E8F84Cd0037CF91154C9a6F",
    };

#if 0
    Wait([&]() noexcept -> task<void> {
        static const Address chainlink("0xF79D6aFBb6dA890132F9D7c355e3015f15F3406F");
        static const Selector<uint256_t> latestRound_("latestRound");
        static const Selector<uint256_t, uint256_t> getTimestamp_("getTimestamp");
        static const Selector<uint256_t, uint256_t> getAnswer_("getAnswer");
        static const uint256_t gas(90000);

        static const auto Ten26(Ten18 * Ten8);
        const auto start(Timestamp());

        uint256_t round(co_await latestRound_.Call(chain, "latest", chainlink, gas) + 1);
        uint256_t timestamp(0);
        Float answer;

        const unsigned needed(83328);

        const auto height(co_await chain->Height());
        //const uint256_t height(10645961);
        for (auto number(height); number != 0; --number) {
            const auto block(co_await chain->Header(number));

            for (; timestamp - 1 > block.timestamp_; --round)
                std::tie(timestamp, answer) = *co_await Parallel(
                    getTimestamp_.Call(chain, "latest", chainlink, gas, round),
                    [&]() -> task<Float> {
                        co_return Float(co_await getAnswer_.Call(chain, "latest", chainlink, gas, round)) / Ten26;
                    }());

            //static const uint256_t Day(24*60*60);
            //orc_insist(start - block.timestamp_ < Day);

            uint256_t limit(block.limit_);

            Pile<uint256_t, uint256_t> prices;
            for (const auto &zipped : Zip(*co_await Parallel(Map([&](const auto &record) {
                return (*chain)[record.hash_];
            }, block.records_)), block.records_)) {
                const auto &receipt(*zipped.get<0>());
                const auto &record(zipped.get<1>());
                const auto &bid(record.bid_);
                const auto &gas(receipt.gas_);
                //if (bid == uint256_t("50000000000"))
                //    Log() << record.hash_ << std::endl;
                static const uint256_t Ten10("10000000000");
                if (record.from_ == block.miner_ ||
                    bid == 0 || bid == 1 ||
                    bid == 1000000000 || bid == Ten10 ||
                miners.find(record.from_) != miners.end())
                    limit -= gas;
                else
                    prices(bid, gas);
            }

            if (!prices.any() || limit < needed)
                continue;
            const auto remain(limit - prices.sum());
            prices(prices.min(), remain);

            const Float wei(prices.val(needed));
            const auto usd(wei * answer);
            const auto gwei(wei / Ten9);

            //if (gwei < 100)
            Log() << std::dec << "#" << block.height_ << " @" << block.timestamp_ << std::fixed <<
                " " << "-" << std::setprecision(1) << remain <<
                " " << "=" << std::setprecision(1) << (Float(prices.med()) / Ten9) <<
                " " << ">" << std::setprecision(1) << gwei <<
                " " << "$" << std::setprecision(2) << (usd * needed) <<
                " " << Human(unsigned(start - block.timestamp_)) <<
            std::endl;

        }
        orc_insist(false);
    }());
#endif

    Site site;

    site(http::verb::get, "/c/1/diff.png", [&](Request request) -> task<Response> {
        std::multimap<uint256_t, std::tuple<uint64_t, uint64_t>> prices;
        uint64_t maximum(0);

        auto number(co_await chain->Height());
        for (unsigned i(0); i != 16; ++i) {
            const auto block(co_await chain->Header(number--));

            for (const auto &zipped : Zip(*co_await Parallel(Map([&](const auto &record) {
                return (*chain)[record.hash_];
            }, block.records_)), block.records_)) {
                const auto &receipt(*zipped.get<0>());
                const auto &record(zipped.get<1>());
                prices.emplace(std::piecewise_construct, std::forward_as_tuple(record.bid_), std::forward_as_tuple(record.gas_, receipt.gas_));
                if (maximum < record.gas_)
                    maximum = record.gas_;
            }
        }

        const unsigned width(1600);
        const unsigned height(1000);

        Surface surface(width, height);
        Cairo cr(surface);
        cairo_scale(cr, width, height);

        cairo_set_source_rgb(cr, 0, 0, 0);
        cairo_rectangle(cr, 0, 0, 1, 1);
        cairo_fill(cr);

        cairo_translate(cr, 0.0, 1.0);
        cairo_scale(cr, 1.0, -1.0);

        cairo_scale(cr, 1.0 / prices.size(), 1.0 / maximum);
        cairo_translate(cr, 0.5, 0.5);

        cairo_set_line_cap(cr, CAIRO_LINE_CAP_SQUARE);
        cairo_set_line_width(cr, 1);

        { unsigned i(0);
        for (const auto &[bid, gas] : prices) {
            const auto &[wanted, needed] = gas;
            cairo_set_source_rgb(cr, 0, 1, 1);
            cairo_move_to(cr, i, 0);
            cairo_line_to(cr, i, wanted);
            cairo_stroke(cr);
            cairo_set_source_rgb(cr, 1, 0, 0);
            cairo_move_to(cr, i, 0);
            cairo_line_to(cr, i, needed);
            cairo_stroke(cr);
        ++i; } }

        co_return Respond(request, http::status::ok, {
            {"content-type", "image/png"},
        }, surface.png());
    });

    site(http::verb::get, "/c/1/gas.png", [&](Request request) -> task<Response> {
        auto number(co_await chain->Height());
        Pile<uint256_t, uint64_t> prices;
        uint64_t limit(0);

        for (unsigned i(0); i != 128; ++i) {
            const auto block(co_await chain->Header(number--));
            limit += block.limit_;

            for (const auto &zipped : Zip(*co_await Parallel(Map([&](const auto &record) {
                return (*chain)[record.hash_];
            }, block.records_)), block.records_)) {
                const auto &receipt(*zipped.get<0>());
                const auto &record(zipped.get<1>());
                const auto &bid(record.bid_);
                const auto &gas(receipt.gas_);
#if 0
                //if (bid == uint256_t("50000000000"))
                //    Log() << record.hash_ << std::endl;
                static const uint256_t Ten10("10000000000");
                if (record.from_ == block.miner_ ||
                    bid == 0 || bid == 1 ||
                    bid == 1000000000 || bid == Ten10 ||
                miners.find(record.from_) != miners.end())
                    limit -= gas;
                else
#else
                if (record.from_ != block.miner_)
#endif
                    prices(bid, gas);
            }
        }

        const unsigned width(1600);
        const unsigned height(1000);

        Surface surface(width, height);
        Cairo cr(surface);
        cairo_scale(cr, width, height);

        cairo_set_source_rgb(cr, 0, 0, 0);
        cairo_rectangle(cr, 0, 0, 1, 1);
        cairo_fill(cr);

        cairo_translate(cr, 0.0, 1.0);
        cairo_scale(cr, 1.0, -1.0);

        cairo_set_line_cap(cr, CAIRO_LINE_CAP_SQUARE);
        cairo_set_line_width(cr, 1);

        cairo_scale(cr, 1.0, 1.0 / 500.0);

        const auto sum(prices.sum());
        const auto dead(limit - sum);

        cairo_scale(cr, 1.0 / limit, 1.0);
        cairo_translate(cr, 0.5, 0.5);

        { Scope scope(cr);
            cairo_set_line_width(cr, 1);
            cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 1.0);

            { uint64_t offset(dead);
            for (const auto &[value, weight] : prices) {
                cairo_rectangle(cr, offset, 0, weight, double(Float(value) / Ten9));
                cairo_stroke_preserve(cr);
                cairo_fill(cr);
            offset += weight; } }
        }

        cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
        cairo_move_to(cr, dead, 0);
        cairo_line_to(cr, dead, 500 - 1);
        cairo_stroke(cr);

        const auto level([&](double red, double green, double blue, const auto &value) {
            cairo_set_source_rgb(cr, red, green, blue);
            cairo_move_to(cr, 0, double(value));
            cairo_line_to(cr, limit - 1, double(value));
            cairo_stroke(cr);
        });

        level(0.0, 0.0, 0.0, 100);
        level(0.0, 0.0, 0.0, 200);
        level(0.0, 0.0, 0.0, 300);
        level(0.0, 0.0, 0.0, 400);

        const auto pct40(double(Float(prices.val(sum*0.40)) / Ten9));
        const auto pct60(double(Float(prices.val(sum*0.60)) / Ten9));

        cairo_set_source_rgba(cr, 0.5, 1.0, 0.5, 0.3);
        cairo_rectangle(cr, 0, pct40, limit, pct60 - pct40);
        cairo_stroke_preserve(cr);
        cairo_fill(cr);

        level(0.5, 1.0, 0.5, pct40);
        level(0.5, 1.0, 0.5, pct60);


        level(1.0, 0.5, 0.5, Float(co_await chain->Bid()) / Ten9);

        co_await gauge->Update();
        level(0.5, 0.5, 1.0, Float(gauge->Price()) / Ten9);

#if 0
        cairo_set_source_rgb(cr, 0, 0, 0);
        cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
        cairo_set_font_size(cr, 40.0);

        cairo_move_to(cr, 10.0, 50.0);
        cairo_show_text(cr, "Disziplin ist Macht.");
#endif
        co_return Respond(request, http::status::ok, {
            {"content-type", "image/png"},
        }, surface.png());
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
