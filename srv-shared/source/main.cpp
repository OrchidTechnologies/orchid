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


#include <cstdio>
#include <iostream>
#include <regex>

#ifdef __linux__
#include <ifaddrs.h>
#endif

#include <unistd.h>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include "libplatform/libplatform.h"
#include "v8.h"

#include <api/jsep_session_description.h>
#include <pc/webrtc_sdp.h>

#include <rtc_base/message_digest.h>
#include <rtc_base/openssl_identity.h>
#include <rtc_base/ssl_fingerprint.h>

#include "baton.hpp"
#include "binance.hpp"
#include "boring.hpp"
#include "butcher.hpp"
#include "cashier.hpp"
#include "chain.hpp"
#include "channel.hpp"
#include "croupier.hpp"
#include "crypto.hpp"
#include "egress.hpp"
#include "executor.hpp"
#include "fiat.hpp"
#include "jsonrpc.hpp"
#include "load.hpp"
#include "local.hpp"
#include "lottery0.hpp"
#include "lottery1.hpp"
#include "node.hpp"
#include "remote.hpp"
#include "scope.hpp"
#include "sequence.hpp"
#include "server.hpp"
#include "site.hpp"
#include "store.hpp"
#include "syscall.hpp"
#include "task.hpp"
#include "transport.hpp"
#include "tunnel.hpp"
#include "updater.hpp"
#include "version.hpp"

namespace orc {

namespace po = boost::program_options;

int TestWorker(const asio::ip::address &bind, uint16_t port, const std::string &key, const std::string &certificates, const std::string &params);

task<bool> Symmetric(const S<Base> &base) {
    const auto offer(co_await Description(base, {"stun:stun1.l.google.com:19302", "stun:stun2.l.google.com:19302"}));
    std::cout << std::endl;
    std::cout << Filter(false, offer) << std::endl;

    webrtc::JsepSessionDescription jsep(webrtc::SdpType::kOffer);
    webrtc::SdpParseError error;
    orc_assert(webrtc::SdpDeserialize(offer, &jsep, &error));

    auto description(jsep.description());
    orc_assert(description != nullptr);

    std::map<Socket, Socket> reflexive;

    for (size_t i(0); ; ++i) {
        const auto ices(jsep.candidates(i));
        if (ices == nullptr)
            break;
        for (size_t i(0), e(ices->count()); i != e; ++i) {
            const auto ice(ices->at(i));
            orc_assert(ice != nullptr);
            const auto &candidate(ice->candidate());
            if (candidate.type() != "stun")
                continue;
            if (!reflexive.emplace(candidate.related_address(), candidate.address()).second)
                co_return true;
        }
    }

    co_return false;
}

int Main(int argc, const char *const argv[]) {
    std::vector<std::string> chains;

    po::variables_map args;

    po::options_description group("general command line (the usual)");
    group.add_options()
        ("help", "produce (probably this) help message")
        ("verbose", "output (mostly useless) log messages")
        ("version", "dump version (intense, with patches)")
    ;

    po::options_description internal("lottery contracts (developers)");
    internal.add_options()
        ("lottery0", po::value<std::string>()->default_value("0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1"))
        ("lottery1", po::value<std::string>()->default_value("0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82"))
    ;

    po::options_description options;

    { po::options_description group("bandwidth pricing (optional)");
    group.add_options()
        ("currency", po::value<std::string>()->default_value("USD"), "currency used for price conversions")
        ("price", po::value<std::string>()->default_value("0.00"), "price of bandwidth in currency / GB")
    ; options.add(group); }

    { po::options_description group("evm json/rpc server (required)");
    group.add_options()
        ("chain", po::value<std::vector<std::string>>(&chains), "like 1,ETH,https://cloudflare-eth.com/")
    ; options.add(group); }

    { po::options_description group("payment addresses (if charging)");
    group.add_options()
        ("executor", po::value<std::string>(), "raw (hex) private key of gas account")
        ("recipient", po::value<std::string>(), "deposit address for client payments")
    ; options.add(group); }

    { po::options_description group("webrtc signaling (basic stuff)");
    group.add_options()
        ("host", po::value<std::string>(), "external hostname for this server")
        ("bind", po::value<std::string>()->default_value("0.0.0.0"), "ip address for server to bind to")
        ("port", po::value<uint16_t>()->default_value(8443), "port to advertise on blockchain")
        ("tls", po::value<std::string>(), "tls keys and chain (pkcs#12 encoded)")
        ("dh", po::value<std::string>(), "diffie hellman params (pem encoded)")
        ("network", po::value<std::string>(), "local interface for ICE candidates")
        ("stun", po::value<std::string>()->default_value("stun.l.google.com:19302"), "stun server url to use for discovery")
    ; options.add(group); }

    { po::options_description group("packet egress (exactly one)");
    group.add_options()
#ifdef __linux__
        ("tunnel", po::value<std::string>(), "/dev/net/tun interface (Linux-only)")
#endif
        ("openvpn", po::value<std::string>(), "OpenVPN .ovpn configuration file")
        ("wireguard", po::value<std::string>(), "WireGuard .conf configuration file")
    ; options.add(group); }

    po::positional_options_description positional;

    po::store(po::command_line_parser(argc, argv).options(po::options_description()
        .add(group)
        .add(options)
        .add(internal)
    ).positional(positional).style(po::command_line_style::default_style
        ^ po::command_line_style::allow_guessing
    ).run(), args);

    if (auto path = getenv("ORCHID_CONFIG"))
        po::store(po::parse_config_file(path, po::options_description()
            .add(options)
            .add(internal)
        ), args);

    po::notify(args);

    if (args.count("help") != 0) {
        std::cout << po::options_description()
            .add(group)
            .add(options)
        << std::endl;

        return 0;
    }

    if (args.count("verbose") != 0)
        Verbose = true;

    if (args.count("version") != 0) {
        std::cout.write(VersionData, Fit(VersionSize));
        return 0;
    }


    Initialize();

    std::vector<std::string> ice;
    ice.emplace_back("stun:" + args["stun"].as<std::string>());


    const auto params(args.count("dh") == 0 ? Params() : Load(args["dh"].as<std::string>()));


    const auto store([&]() -> Store {
        if (args.count("tls") != 0)
            return Load(args["tls"].as<std::string>());
        else {
            const auto pem(Certify()->ToPEM());
            auto key(pem.private_key());
            auto certificate(pem.certificate());

            // XXX: generate .p12 file (for Nathan)
            std::cout << key << std::endl;
            std::cout << certificate << std::endl;

            return {std::move(key), std::move(certificate)};
        }
    }());


    // XXX: the return type of OpenSSLIdentity::FromPEMStrings should be changed :/
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-static-cast-downcast)
    //U<rtc::OpenSSLIdentity> identity(static_cast<rtc::OpenSSLIdentity *>(rtc::OpenSSLIdentity::FromPEMStrings(store.Key(), store.Certificates()));

    rtc::scoped_refptr<rtc::RTCCertificate> certificate(rtc::RTCCertificate::FromPEM(rtc::RTCCertificatePEM(store.Key(), store.Certificates())));
    U<rtc::SSLFingerprint> fingerprint(rtc::SSLFingerprint::CreateFromCertificate(*certificate));


    std::string host;
    if (args.count("host") != 0)
        host = args["host"].as<std::string>();
    else
        // XXX: this should be the IP of "bind"
        host = boost::asio::ip::host_name();

    const auto port(args["port"].as<uint16_t>());
    //return TestWorker(asio::ip::make_address(args["bind"].as<std::string>()), port, store.Key(), store.Certificates(), params);

    const Strung url("https://" + host + ":" + std::to_string(port) + "/");
    Bytes gpg;

    Builder tls;
    static const std::regex re("-");
    tls += Abstract(std::regex_replace(fingerprint->algorithm, re, "").c_str());
    tls += Subset(fingerprint->digest.data(), fingerprint->digest.size());

    std::cout << "url = " << url << std::endl;
    std::cout << "tls = " << tls << std::endl;
    std::cout << "gpg = " << gpg << std::endl;
    std::cout << std::endl;


    S<Base> base(args.count("network") == 0 ? Break<Local>() : Break<Local>(args["network"].as<std::string>()));
    orc_assert_(!Wait(Symmetric(base)), "server must not use symmetric NAT");


    auto cashier([&]() -> S<Cashier> {
        const auto price(Float(args["price"].as<std::string>()) / (1024 * 1024 * 1024));
        return price == 0 ? nullptr : Make<Cashier>(price);
    }());


    auto croupier(Wait([&]() -> task<S<Croupier>> {
        orc_assert_(args["currency"].as<std::string>() == "USD", "--currency currently must be USD (sorry)");

        if (cashier == nullptr) co_return nullptr;
        orc_assert_(args.count("executor") != 0, "must specify --executor unless --price is 0 (see --help)");
        auto executor(Make<SecretExecutor>(Bless(args["executor"].as<std::string>())));
        const auto recipient(args.count("recipient") == 0 ? Address(*executor) : Address(args["recipient"].as<std::string>()));

        const unsigned milliseconds(5*60*1000);
        const auto ethereum(co_await Ethereum::New(base, chains));
        const auto markets(co_await Market::All(milliseconds, ethereum, base, chains));

        for (const auto &market : markets) {
            const auto bid((*market.bid_)());
            Log() << std::dec << market.chain_->operator const uint256_t &() << ":" << market.currency_.name_ << " $" << (Float(bid) * market.currency_.dollars_() * 100000) << " @" << std::dec << bid << std::endl;
        }

        auto lottery0(co_await [&]() -> task<S<Lottery0>> {
            for (const auto &market : markets)
                if (*market.chain_ == 1) {
                    const Address contract(args["lottery0"].as<std::string>());
                    static Selector<Address> what_("what");

                    auto lottery0(Break<Lottery0>(Token{market,
                        co_await what_.Call(*market.chain_, "latest", contract, 90000),
                        co_await Binance(milliseconds, base, "OXT")
                    }, contract));

                    lottery0->Open();
                    co_return lottery0;
                }
            orc_assert_(false, "must provide --chain 1,ETH,https://... (see --help)");
        }());

        const Address contract(args["lottery1"].as<std::string>());

        std::map<uint256_t, S<Lottery1>> lotteries1;
        for (const auto &market : markets) {
            auto lottery1(Break<Lottery1>(market, contract));
            lottery1->Open();
            lotteries1.try_emplace(*market.chain_, std::move(lottery1));
        }

        auto croupier(Make<Croupier>(recipient, std::move(executor), std::move(lottery0), std::move(lotteries1)));
        co_return std::move(croupier);
    }()));


    auto egress([&]() { if (false) {
#ifdef __linux__
    } else if (args.count("tunnel") != 0) {
        const auto tunnel(args["tunnel"].as<std::string>());

        ifaddrs *addresses;
        orc_syscall(getifaddrs(&addresses));
        _scope({ freeifaddrs(addresses); });

        const auto local([&]() -> Socket {
            for (const auto *address(addresses); address != nullptr; address = address->ifa_next)
                if (address->ifa_name == tunnel && address->ifa_addr != nullptr) {
                    orc_assert_((address->ifa_flags & IFF_POINTOPOINT) != 0, "tunnel must be point-to-point");
                    orc_assert_(address->ifa_dstaddr != nullptr, "tunnel must have destination");
                    return *address->ifa_dstaddr;
                }
            orc_assert_(false, "cannot find interface " << tunnel);
        }());

        auto egress(Break<BufferSink<Egress>>(local.Host().operator uint32_t()));
        Tunnel(*egress, tunnel, [&](const std::string &) {});
        return egress;
#endif
    } else if (args.count("openvpn") != 0) {
        const auto file(Load(args["openvpn"].as<std::string>()));
        auto egress(Break<BufferSink<Egress>>(0));
        Wait(Connect(*egress, base, 0, file, "", ""));
        return egress;
    } else if (args.count("wireguard") != 0) {
        const auto file(Load(args["wireguard"].as<std::string>()));
        auto egress(Break<BufferSink<Egress>>(0));
        Wait(Guard(*egress, base, 0, file));
        return egress;
    } else orc_assert_(false, "must provide an egress option (see --help)"); }());

    Wait([&]() -> task<void> {
        auto remote(Break<BufferSink<Remote>>());
        Egress::Wire(egress, *remote);
        remote->Open();
        co_await remote->Resolve("one.one.one.one", "443");
        if (co_await Symmetric(remote))
            Log() << "egress should not use symmetric NAT" << std::endl;
    }());


    const auto node(Make<Node>(std::move(base), std::move(cashier), std::move(croupier), std::move(egress), std::move(ice)));
    node->Run(asio::ip::make_address(args["bind"].as<std::string>()), port, store.Key(), store.Certificates(), params);
    return 0;
}

}

int main(int argc, const char *const argv[]) { try {
    v8::V8::InitializeICUDefaultLocation(argv[0]);
    v8::V8::InitializeExternalStartupData(argv[0]);

    const auto platform(v8::platform::NewDefaultPlatform());
    v8::V8::InitializePlatform(platform.get());
    _scope({ v8::V8::ShutdownPlatform(); });

    v8::V8::Initialize();
    _scope({ v8::V8::Dispose(); });

    return orc::Main(argc, argv);
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    return 1;
} }
