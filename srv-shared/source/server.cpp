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

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include <asio/connect.hpp>
#include <asio/io_context.hpp>
#include <asio/signal_set.hpp>
#include <asio/write.hpp>

#include <asio.hpp>

#include <unistd.h>

#include <microhttpd.h>

#include "baton.hpp"
#include "channel.hpp"
#include "crypto.hpp"
//#include "ethereum.hpp"
#include "http.hpp"
#include "scope.hpp"
#include "secure.hpp"
#include "shared.hpp"
#include "socket.hpp"
#include "task.hpp"
#include "trace.hpp"

#include <folly/futures/Future.h>
#include <folly/executors/CPUThreadPoolExecutor.h>

#define _disused \
    __attribute__((__unused__))


namespace po = boost::program_options;

namespace orc {

static po::variables_map args;

static std::vector<std::string> ices_;

class Back {
  public:
    virtual task<std::string> Respond(const std::string &offer) = 0;
};

class Outgoing :
    public Connection
{
  public:
    Outgoing() :
        Connection(ices_)
    {
    }

    void OnChannel(U<Channel> channel) override {
    }
};

template <typename Type_>
class Output :
    public Pipe
{
  private:
    Sink<Type_> sink_;

  public:
    Output(const W<Pipe> &path, const Tag &tag, U<Type_> link) :
        sink_([weak = path, tag](const Buffer &data) {
            if (auto strong = weak.lock())
                Task([strong = std::move(strong), tag, data = Beam(data)]() -> task<void> {
                    co_await strong->Send(Tie(tag, data));
                });
        }, std::move(link))
    {
        _trace();
    }

    virtual ~Output() {
        _trace();
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await sink_.Send(data);
    }

    Type_ *operator ->() {
        return sink_.operator ->();
    }
};

class Account :
    public std::enable_shared_from_this<Account>,
    public Pipe
{
  private:
    S<Back> back_;

    Pipe *input_;

    std::map<Tag, U<Pipe>> outputs_;
    std::map<Tag, S<Outgoing>> outgoing_;

  public:
    Account(const S<Back> &back) :
        back_(back)
    {
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
        _assert(input_ != nullptr);
        co_return co_await input_->Send(data);
    }


    void Land(const Buffer &data) {
        Beam unboxed(data);
        Task([unboxed = std::move(unboxed), self = shared_from_this()]() -> task<void> {
            auto [nonce, rest] = Take<TagSize, 0>(unboxed);
            auto output(self->outputs_.find(nonce));
            if (output != self->outputs_.end()) {
                co_await output->second->Send(rest);
            } else {
                auto [command, args] = Take<TagSize, 0>(rest);
                if (false) {

                } else if (command == CloseTag) {
                    const auto [tag] = Take<TagSize>(args);
                    self->outputs_.erase(tag);
                    co_await self->Send(Tie(nonce));


                } else if (command == ConnectTag) {
                    const auto [tag, target] = Take<TagSize, 0>(args);
                    auto string(target.str());
                    auto colon(string.find(':'));
                    _assert(colon != std::string::npos);
                    auto host(string.substr(0, colon));
                    auto port(string.substr(colon + 1));
                    auto socket(std::make_unique<Socket<asio::ip::tcp::socket>>());
                    auto output(std::make_unique<Output<Socket<asio::ip::tcp::socket>>>(self, tag, std::move(socket)));
                    co_await (*output)->_(host, port);
                    self->outputs_[tag] = std::move(output);
                    co_await self->Send(Tie(nonce));


                } else if (command == EstablishTag) {
                    const auto [handle] = Take<TagSize>(args);
                    auto outgoing(std::make_shared<Outgoing>());
                    self->outgoing_[handle] = outgoing;
                    co_await self->Send(Tie(nonce));

                } else if (command == OfferTag) {
                    const auto [handle] = Take<TagSize>(args);
                    auto outgoing(self->outgoing_.find(handle));
                    _assert(outgoing != self->outgoing_.end());
                    auto offer(co_await outgoing->second->Offer());
                    co_await self->Send(Tie(nonce, Beam(offer)));

                } else if (command == NegotiateTag) {
                    const auto [handle, answer] = Take<TagSize, 0>(args);
                    auto outgoing(self->outgoing_.find(handle));
                    _assert(outgoing != self->outgoing_.end());
                    co_await outgoing->second->Negotiate(answer.str());
                    co_await self->Send(Tie(nonce));

                } else if (command == ChannelTag) {
                    const auto [handle, tag] = Take<TagSize, TagSize>(args);
                    auto outgoing(self->outgoing_.find(handle));
                    _assert(outgoing != self->outgoing_.end());
                    auto channel(std::make_unique<Channel>(outgoing->second));
                    self->outputs_[tag] = std::make_unique<Output<Channel>>(self, tag, std::move(channel));
                    co_await self->Send(Tie(nonce));

                } else if (command == CancelTag) {
                    const auto [handle] = Take<TagSize>(args);
                    self->outgoing_.erase(handle);
                    co_await self->Send(Tie(nonce));

                } else if (command == FinishTag) {
                    const auto [tag] = Take<TagSize>(args);
                    auto output(self->outputs_.find(tag));
                    _assert(output != self->outputs_.end());
                    auto channel(dynamic_cast<Output<Channel> *>(output->second.get()));
                    _assert(channel != NULL);
                    co_await (*channel)->_();
                    co_await self->Send(Tie(nonce));


                } else if (command == AnswerTag) {
                    const auto [offer] = Take<0>(args);
                    auto answer(co_await self->back_->Respond(offer.str()));
                    co_await self->Send(Tie(nonce, Beam(answer)));

                } else _assert(false);
            }
        });
    }
};

class Node :
    public std::enable_shared_from_this<Node>,
    public Identity,
    public Back
{
    friend class Incoming;

  private:
    std::map<Common, W<Account>> accounts_;
    std::set<S<Connection>> clients_;

  public:
    virtual ~Node() {
    }

    S<Account> Find(const Common &common) {
        auto &cache(accounts_[common]);
        if (auto account = cache.lock())
            return account;
        auto account(std::make_shared<Account>(shared_from_this()));
        cache = account;
        return account;
    }

    task<std::string> Respond(const std::string &offer) override;
};

class Conduit :
    public Pipe
{
  private:
    S<Node> node_;
    Sink<Secure> sink_;

    S<Account> account_;

  public:
    S<Pipe> self_;

  public:
    Conduit(const S<Node> &node, U<Link> channel) :
        node_(node),
        sink_([this](const Buffer &data) {
            if (data.empty())
                self_.reset();
            else {
                _assert(account_ != nullptr);
                account_->Land(data);
            }
        }, std::make_unique<Secure>(true, std::move(channel), []() -> bool {
            return true;
        }))
    {
        Identity identity;
        account_ = node_->Find(identity.GetCommon());
        account_->Associate(this);
    }

    virtual ~Conduit() {
        if (account_ != nullptr)
            account_->Dissociate(this);
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await sink_.Send(data);
    }
};

class Incoming :
    public Connection
{
  private:
    S<Node> node_;

  public:
    Incoming(S<Node> node) :
        Connection(ices_),
        node_(std::move(node))
    {
    }

    ~Incoming() {
        _trace();
    }

    void OnChannel(U<Channel> channel) override {
        auto conduit(std::make_shared<Conduit>(node_, std::move(channel)));
        conduit->self_ = conduit;
        // XXX: also automatically remove this after some timeout
        // XXX: this was temporarily removed due to thread issues
        // node_->clients_.erase(shared_from_this());
    }
};

task<std::string> Node::Respond(const std::string &offer) {
    auto client(std::make_shared<Incoming>(shared_from_this()));
    auto answer(co_await client->Answer(offer));
    clients_.emplace(client);
    co_return answer;
}

}


static MHD_Daemon *http_;

struct Internal {
    orc::S<orc::Node> node_;
};

struct Request {
    std::string offer_;

    Request() {
    }
};

static int Data(struct MHD_Connection *connection, const std::string &mime, const std::string &data, int status = MHD_HTTP_OK) {
    auto response(MHD_create_response_from_buffer(data.size(), const_cast<char *>(data.data()), MHD_RESPMEM_MUST_COPY));
    _scope({ MHD_destroy_response(response); });
    MHD_add_response_header(response, "Content-Type", mime.c_str());
    auto result(MHD_queue_response(connection, status, response));
    return result;
}

static int Respond(void *arg, struct MHD_Connection *connection, const char *url, const char *method, const char *version, const char *data, size_t *size, void **baton) {
    _disused auto internal(static_cast<Internal *>(arg));
    _disused auto request(static_cast<Request *>(*baton));
    if (request == NULL) {
        *baton = request = new Request();
        return MHD_YES;
    }

    if (*size != 0) {
        request->offer_.append(data, *size);
        *size = 0;
        return MHD_YES;
    }

    if (strcmp(url, "/") != 0)
        return Data(connection, "text/plain", "", MHD_HTTP_NOT_FOUND);


    try {
        auto answer(orc::Wait(internal->node_->Respond(request->offer_)));

        orc::Log() << std::endl;
        orc::Log() << "^^^^^^^^^^^^^^^^" << std::endl;
        orc::Log() << request->offer_ << std::endl;
        orc::Log() << "================" << std::endl;
        orc::Log() << answer << std::endl;
        orc::Log() << "vvvvvvvvvvvvvvvv" << std::endl;
        orc::Log() << std::endl;

        return Data(connection, "text/plain", answer);
    } catch (...) {
_trace();
        return Data(connection, "text/plain", "", MHD_HTTP_NOT_FOUND);
    }
}

static void Complete(void *arg, MHD_Connection *connection, void **baton, MHD_RequestTerminationCode code) {
    _disused auto internal(static_cast<Internal *>(arg));
    _disused std::unique_ptr<Request> request(static_cast<Request *>(*baton));
    *baton = NULL;
}

static void Connect(void *arg, MHD_Connection *connection, void **socket, MHD_ConnectionNotificationCode code) {
    _disused auto internal(static_cast<Internal *>(arg));
}

static void LogMHD(void *, const char *format, va_list args) {
    orc::Log()(format, args);
}

namespace orc {
int Main(int argc, const char *const argv[]) {
    po::options_description options("command-line (only)");
    options.add_options()
        ("help", "produce help message")
    ;

    po::options_description configs("command-line / file");
    configs.add_options()
        ("rendezvous-port", po::value<uint16_t>()->default_value(8080), "port to advertise on blockchain")
        ("ice-stun-server", po::value<std::string>()->default_value("stun:stun.l.google.com:19302"), "stun server url to use for discovery")
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

    ices_.emplace_back(args["ice-stun-server"].as<std::string>());

    auto internal(new Internal{});
    internal->node_ = std::make_shared<Node>();

    http_ = MHD_start_daemon(MHD_USE_SELECT_INTERNALLY | MHD_USE_DEBUG, args["rendezvous-port"].as<uint16_t>(), NULL, NULL, &Respond, internal,
        MHD_OPTION_EXTERNAL_LOGGER, &LogMHD, NULL,
        MHD_OPTION_NOTIFY_COMPLETED, &Complete, internal,
        MHD_OPTION_NOTIFY_CONNECTION, &Connect, internal,
    MHD_OPTION_END);

    _assert(http_ != NULL);

    asio::signal_set signals(Context(), SIGINT, SIGTERM);
    signals.async_wait([&](auto, auto) { Context().stop(); });

    Thread().join();
    return 0;
} }

int main(int argc, const char *const argv[]) {
    return orc::Main(argc, argv);
}
