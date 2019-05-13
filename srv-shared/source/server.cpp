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


#include <condition_variable>
#include <cstdio>
#include <iostream>
#include <mutex>

#include <unistd.h>

#include <boost/filesystem/string_file.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include <asio/connect.hpp>
#include <asio/io_context.hpp>
#include <asio/signal_set.hpp>
#include <asio/write.hpp>

#include <asio.hpp>

#include <pc/webrtc_sdp.h>
#include <rtc_base/message_digest.h>

#include "baton.hpp"
#include "beast.hpp"
#include "channel.hpp"
#include "commands.hpp"
#include "crypto.hpp"
//#include "ethereum.hpp"
#include "http.hpp"
#include "scope.hpp"
#include "secure.hpp"
#include "socket.hpp"
#include "task.hpp"
#include "trace.hpp"

#define _disused \
    __attribute__((__unused__))


namespace po = boost::program_options;

namespace orc {

static po::variables_map args;

static std::vector<std::string> ice_;

class Back {
  public:
    virtual task<std::string> Respond(const std::string &offer) = 0;
};

class Outgoing final :
    public Connection
{
  protected:
    void Land(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) override {
    }

    void Stop(const std::string &error) override {
        std::terminate();
    }

  public:
    virtual ~Outgoing() {
_trace();
        Close();
    }
};

class Account {
  public:
    virtual void Land(const Buffer &data) = 0;
    virtual void Bill(uint64_t amount) = 0;
};

template <typename Type_>
class Output :
    public Pump<Account>,
    public BufferDrain
{
    template <typename Base_, typename Inner_, typename Drain_>
    friend class Sink;

  private:
    const Tag tag_;

  protected:
    virtual Type_ *Inner() = 0;

    void Land(const Buffer &data) override {
        auto used(Outer());
        used->Bill(1);
        used->Land(Tie(tag_, data));
    }

    void Stop(const std::string &error) override {
        Pump<Account>::Stop();
        // XXX: implement (efficiently ;P)
    }

  public:
    Output(Account *drain, const Tag &tag) :
        Pump<Account>(drain),
        tag_(tag)
    {
_trace();
    }

    virtual ~Output() {
_trace();
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner()->Send(data);
    }

    task<void> Shut() override {
        co_await Inner()->Shut();
        co_await Pump<Account>::Shut();
    }

    Type_ *operator ->() {
        return Inner();
    }
};

class Waiter :
    public Link
{
  private:
    S<Connection> connection_;

  protected:
    virtual Channel *Inner() = 0;

  public:
    Waiter(BufferDrain *drain, S<Connection> connection) :
        Link(drain),
        connection_(connection)
    {
    }

    task<std::string> Connect(const std::string &sdp) {
        auto connection(std::move(connection_));
        orc_assert(connection != nullptr);
        co_await connection->Negotiate(sdp);
        co_await Inner()->Connect();
        co_return webrtc::SdpSerializeCandidate(connection->Candidate());
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner()->Send(data);
    }

    task<void> Shut() {
        co_await Inner()->Shut();
    }
};

class Replay final :
    public Pump<Account>
{
  private:
    Beam request_;
    Beam response_;

  public:
    task<void> Send(const Buffer &data) override {
        orc_assert(request_ == data);
        Outer()->Land(response_);
        co_return;
    }
};

class Space final :
    public std::enable_shared_from_this<Space>,
    public Pipe,
    public Account
{
  private:
    const S<Back> back_;

    Pipe *input_;

    std::map<Tag, U<Pump<Account>>> outputs_;

    int64_t balance_;

  public:
    Space(S<Back> back) :
        back_(std::move(back))
    {
    }

    ~Space() {
_trace();
    }


    // XXX: implement a set

    void Associate(Pipe *input) {
        input_ = input;
    }

    void Dissociate(Pipe *input) {
        if (input_ == input)
            input_ = nullptr;
    }


    task<void> Send(const Buffer &data) override {
        orc_assert(input_ != nullptr);
        Bill(1);
        co_return co_await input_->Send(data);
    }

    task<void> Shut() {
        for (auto &output : outputs_)
            co_await output.second->Shut();
    }


    void Land(const Buffer &data) override {
        Task([self = shared_from_this(), data = Beam(data)]() -> task<void> {
            co_await self->Send(data);
        });
    }

    void Bill(uint64_t amount) override {
        balance_ -= amount;
    }


    task<void> Call(const Buffer &data, std::function<task<void> (const Buffer &)> code) {
        auto [command, args] = Take<TagSize, 0>(data);
        if (false) {


        } else if (command == BatchTag) {
            // XXX: make this more efficient
            std::string builder;
            Call(data, [&](const Buffer &data) -> task<void> {
                builder += data.str();
                co_return;
            });
            co_return co_await code(Tie(Strung(std::move(builder))));

        } else if (command == DiscardTag) {
            co_return;

        } else if (command == CloseTag) {
            const auto [tag] = Take<TagSize>(args);
            auto output(outputs_.find(tag));
            orc_assert(output != outputs_.end());
            co_await output->second->Shut();
            outputs_.erase(output);
            co_return co_await code(Tie());


        } else if (command == ConnectTag) {
            // XXX: use something saner than : separation?
            const auto [tag, target] = Take<TagSize, 0>(args);
            auto string(target.str());
            auto colon(string.rfind(':'));
            orc_assert(colon != std::string::npos);
            auto host(string.substr(0, colon));
            auto port(string.substr(colon + 1));
            auto output(std::make_unique<Sink<Output<Socket<asio::ip::udp::socket>>, Socket<asio::ip::udp::socket>>>(this, tag));
            auto socket(output->Wire<Socket<asio::ip::udp::socket>>());
            auto endpoint(co_await socket->Connect(host, port));
            auto place(outputs_.emplace(tag, std::move(output)));
            orc_assert(place.second);
            co_return co_await code(Tie(Number<uint16_t>(endpoint.port()), Strung(endpoint.address().to_string())));


        } else if (command == OfferTag) {
            const auto [tag] = Take<TagSize>(args);
            auto outgoing(Make<Outgoing>());
            auto output(std::make_unique<Sink<Output<Waiter>, Waiter>>(this, tag));
            auto waiter(output->Wire<Sink<Waiter, Channel>>(outgoing));
            waiter->Wire<Channel>(outgoing);
            auto offer(Strip(co_await outgoing->Offer()));
            auto place(outputs_.emplace(tag, std::move(output)));
            orc_assert(place.second);
            co_return co_await code(Tie(Strung(std::move(offer))));

        } else if (command == NegotiateTag) {
            const auto [tag, answer] = Take<TagSize, 0>(args);
            auto output(outputs_.find(tag));
            orc_assert(output != outputs_.end());
            // XXX: this is extremely unfortunate
            auto waiter(dynamic_cast<Output<Waiter> *>(output->second.get()));
            orc_assert(waiter != NULL);
            auto candidate(co_await (*waiter)->Connect(answer.str()));
            co_return co_await code(Tie(Strung(std::move(candidate))));


        } else if (command == AnswerTag) {
            const auto [offer] = Take<0>(args);
            auto answer(co_await back_->Respond(offer.str()));
            co_return co_await code(Tie(Strung(std::move(answer))));


        } else {
            orc_assert_(false, "unknown command: " << data);
        }
    }

    task<void> Call(const Buffer &data) {
        Bill(1);

        auto [nonce, rest] = Take<TagSize, 0>(data);
        auto output(outputs_.find(nonce));
        if (output != outputs_.end()) {
            Bill(1);
            co_return co_await output->second->Send(rest);
        } else {
            try {
                // reference to local binding 'nonce' declared in enclosing function 'orc::Space::Call'
                co_return co_await Call(rest, [this, &nonce = nonce](const Buffer &data) -> task<void> {
                    co_return co_await Send(Tie(nonce, data));
                });
            } catch (const Error &error) {
                co_return co_await Send(Tie(Zero, nonce, Strung(error.message)));
            }
        }
    }
};

class Ship {
  private:
    rtc::scoped_refptr<rtc::RTCCertificate> certificate_;
    U<rtc::OpenSSLIdentity> identity_;

  public:
    Ship(const std::string &key, const std::string &chain) :
        certificate_(rtc::RTCCertificate::FromPEM(rtc::RTCCertificatePEM(key, chain))),
        // CAST: the return type of OpenSSLIdentity::FromPEMStrings should be changed :/
        identity_(static_cast<rtc::OpenSSLIdentity *>(rtc::OpenSSLIdentity::FromPEMStrings(key, chain)))
    {
        auto fingerprint(rtc::SSLFingerprint::CreateFromCertificate(*certificate_));
        std::cerr << fingerprint->GetRfc4572Fingerprint() << std::endl;
    }

    virtual S<Space> Find(const std::string &fingerprint) = 0;

    rtc::scoped_refptr<rtc::RTCCertificate> Certificate() const {
        return certificate_;
    }

    rtc::OpenSSLIdentity *Identity() const {
        return identity_.get();
    }
};

class Conduit :
    public Pipe,
    public BufferDrain
{
  private:
    S<Pipe> self_;
    S<Space> space_;

    void Assign(S<Space> space) {
        space_ = std::move(space);
        space_->Associate(this);
    }

  protected:
    virtual Secure *Inner() = 0;

    void Land(const Buffer &data) override {
        orc_assert(space_ != nullptr);
        Task([space = space_, data = Beam(data)]() -> task<void> {
            space->Bill(1);
            co_return co_await space->Call(data);
        });
    }

    void Stop(const std::string &error) override {
        Task([this]() -> task<void> {
            co_await Inner()->Shut();
            // XXX: space needs to be reference counted
            co_await space_->Shut();
            self_.reset();
        });
    }

  public:
    static std::pair<S<Conduit>, Sink<Secure> *> Spawn(S<Ship> ship) {
        auto conduit(Make<Sink<Conduit, Secure>>());
        conduit->self_ = conduit;
        auto secure(conduit->Wire<Sink<Secure>>(true, ship->Identity(), [ship, conduit = conduit.get()](const rtc::OpenSSLCertificate &certificate) -> bool {
            auto fingerprint(rtc::SSLFingerprint::Create(rtc::DIGEST_SHA_256, certificate));
            auto space(ship->Find(fingerprint->GetRfc4572Fingerprint()));
            conduit->Assign(std::move(space));
            return true;
        }));
        return {conduit, secure};
    }

    task<void> Connect() {
        co_await Inner()->Connect();
    }

    virtual ~Conduit() {
_trace();
        if (space_ != nullptr)
            space_->Dissociate(this);
    }

    task<void> Send(const Buffer &data) override {
        space_->Bill(1);
        co_return co_await Inner()->Send(data);
    }
};

class Incoming final :
    public Connection
{
  private:
    S<Incoming> self_;

    const S<Ship> ship_;

  protected:
    void Land(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) override {
        auto [conduit, inner](Conduit::Spawn(ship_));
        auto channel(inner->Wire<Channel>(shared_from_this(), interface));

        Task([conduit = conduit, channel]() -> task<void> {
            co_await channel->Connect();
            co_await conduit->Connect();
        });
    }

    void Stop(const std::string &error) override {
        self_.reset();
    }

  public:
    Incoming(S<Ship> ship) :
        Connection([&]() {
            Configuration configuration;
            configuration.ice_ = ice_;
            configuration.tls_ = ship->Certificate();
            return configuration;
        }()),
        ship_(std::move(ship))
    {
    }

    template <typename... Args_>
    static S<Incoming> Spawn(Args_ &&...args) {
        auto self(Make<Incoming>(std::forward<Args_>(args)...));
        self->self_ = self;
        return self;
    }

    virtual ~Incoming() {
_trace();
        Close();
    }
};

class Node final :
    public std::enable_shared_from_this<Node>,
    public Back,
    public Ship,
    public Identity
{
  private:
    std::mutex mutex_;
    std::map<std::string, W<Space>> spaces_;

  public:
    Node(const std::string &key, const std::string &chain) :
        Ship(key, chain)
    {
    }

    virtual ~Node() {
_trace();
    }

    S<Space> Find(const std::string &fingerprint) override {
        std::unique_lock<std::mutex> lock(mutex_);
        auto &cache(spaces_[fingerprint]);
        if (auto space = cache.lock())
            return space;
        auto space(Make<Space>(shared_from_this()));
        cache = space;
        return space;
    }

    task<std::string> Respond(const std::string &offer) override {
        auto incoming(Incoming::Spawn(shared_from_this()));
        auto answer(co_await incoming->Answer(offer));
        //answer = boost::regex_replace(std::move(answer), boost::regex("\r?\na=candidate:[^ ]* [^ ]* [^ ]* [^ ]* 10\\.[^\r\n]*"), "")
        co_return answer;
    }
};

int Main(int argc, const char *const argv[]) {
    po::options_description options("command-line (only)");
    options.add_options()
        ("help", "produce help message")
    ;

    po::options_description configs("command-line / file");
    configs.add_options()
        ("diffie-hellman", po::value<std::string>(), "diffie hellman (.pem encoded)")
        ("ethereum-api-url", po::value<std::string>(), "ethereum json/rpc and websocket endpoint")
        ("ice-stun-server", po::value<std::string>()->default_value("stun:stun.l.google.com:19302"), "stun server url to use for discovery")
        ("rendezvous-port", po::value<uint16_t>()->default_value(8080), "port to advertise on blockchain")
        ("tls-certificate", po::value<std::string>(), "tls certificate (.pem encoded)")
        ("tls-private-key", po::value<std::string>(), "tls private key (.pem encoded)")
        ("ovpn-config-file", po::value<std::string>(), "openvpn .ovpn configuration file")
    ;

    po::options_description hiddens("you can't see these");
    hiddens.add_options()
    ;

    po::store(po::parse_command_line(argc, argv, po::options_description()
        .add(options)
        .add(configs)
        .add(hiddens)
    ), args);

    if (auto path = getenv("ORCHID_CONFIG"))
        po::store(po::parse_config_file(path, po::options_description()
            .add(configs)
            .add(hiddens)
        ), args);

    po::notify(args);

    if (args.count("help")) {
        std::cout << po::options_description()
            .add(options)
            .add(configs)
        << std::endl;

        return 0;
    }

    ice_.emplace_back(args["ice-stun-server"].as<std::string>());


    std::string chain;
    boost::filesystem::load_string_file(args["tls-certificate"].as<std::string>(), chain);

    std::string key;
    boost::filesystem::load_string_file(args["tls-private-key"].as<std::string>(), key);

    std::string dh;
    boost::filesystem::load_string_file(args["diffie-hellman"].as<std::string>(), dh);


    auto node(Make<Node>(key, chain));


    boost::asio::ssl::context context{boost::asio::ssl::context::tlsv12};

    context.set_options(
        boost::asio::ssl::context::default_workarounds |
        boost::asio::ssl::context::no_sslv2 |
        boost::asio::ssl::context::single_dh_use |
    0);

    context.use_certificate_chain(boost::asio::buffer(chain.data(), chain.size()));
    context.use_private_key(boost::asio::buffer(key.data(), key.size()), boost::asio::ssl::context::file_format::pem);
    context.use_tmp_dh(boost::asio::buffer(dh.data(), dh.size()));


#ifdef _WIN32
    static boost::asio::windows::stream_handle out(Context(), GetStdHandle(STD_OUTPUT_HANDLE));
#else
    static boost::asio::posix::stream_descriptor out(Context(), ::dup(STDOUT_FILENO));
#endif

    http::basic_router<SslHttpSession> router{boost::regex::ECMAScript};

    router.post("/", [&](auto request, auto context) {
        http::out::pushn<std::ostream>(out, request);

        try {
            auto offer(request.body());
            auto answer(Wait(node->Respond(offer)));

            Log() << std::endl;
            Log() << "^^^^^^^^^^^^^^^^" << std::endl;
            Log() << offer << std::endl;
            Log() << "================" << std::endl;
            Log() << answer << std::endl;
            Log() << "vvvvvvvvvvvvvvvv" << std::endl;
            Log() << std::endl;

            context.send(Response(request, "text/plain", answer));
        } catch (...) {
            context.send(Response(request, "text/plain", "", boost::beast::http::status::not_found));
        }
    });

    router.all(R"(^.*$)", [&](auto request, auto context) {
        http::out::pushn<std::ostream>(out, request);
        context.send(Response(request, "text/plain", ""));
    });

    auto fail([](auto code, auto from) {
        Log() << "ERROR " << code << " " << from << std::endl;
    });

    HttpListener::launch(Context(), {
        asio::ip::make_address("0.0.0.0"),
        args["rendezvous-port"].as<uint16_t>()
    }, [&](auto socket) {
        SslHttpSession::handshake(context, std::move(socket), router, [](auto context) {
            context.recv();
        }, fail);
    }, fail);


    asio::signal_set signals(Context(), SIGINT, SIGTERM);
    signals.async_wait([&](auto, auto) { Context().stop(); });

    Thread().join();
    return 0;
}

}

int main(int argc, const char *const argv[]) {
    return orc::Main(argc, argv);
}
