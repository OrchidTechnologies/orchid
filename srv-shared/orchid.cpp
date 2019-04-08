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

#include <asio/connect.hpp>
#include <asio/io_context.hpp>
#include <asio/signal_set.hpp>
#include <asio/write.hpp>

#include <asio.hpp>

#include <unistd.h>

#include <microhttpd.h>

#include "baton.hpp"
#include "crypto.hpp"
//#include "ethereum.hpp"
#include "http.hpp"
#include "scope.hpp"
#include "shared.hpp"
#include "socket.hpp"
#include "spawn.hpp"
#include "trace.hpp"
#include "webrtc.hpp"

#define _disused \
    __attribute__((__unused__))


namespace orc {

class Client;

class Outstanding :
    public Connection
{
  public:
    void OnChannel(U<Channel> channel) override {
    }
};

class Output :
    public Pipe
{
  private:
    Sink<> sink_;

  public:
    Output(const W<Pipe> &path, const Tag &tag, U<Link> link) :
        sink_(std::move(link), [weak = path, tag](const Buffer &data) {
            if (auto strong = weak.lock())
                strong->Send(Tie(tag, data));
        })
    {
        _trace();
    }

    virtual ~Output() {
        _trace();
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        co_return co_await sink_.Send(data);
    }
};

class Account;
class Input;

class Node :
    public std::enable_shared_from_this<Node>,
    public Identity
{
    friend class Client;

  private:
    // XXX: this should be a weak set
    std::map<Common, S<Account>> accounts_;

    typedef std::pair<Pipe *, Tag> Key_;
    std::map<Key_, S<Input>> inputs_;

    std::set<S<Connection>> clients_;

  public:
    void Land(const S<Pipe> &path, const Buffer &data);

    cppcoro::task<std::string> Respond(const std::string &offer);
};

class Account :
    public std::enable_shared_from_this<Account>,
    public Link
{
  private:
    S<Node> node_;
    Boxer boxer_;

    Pipe *input_;

    std::map<Tag, U<Output>> outputs_;
    std::map<Tag, S<Outstanding>> outstandings_;

  public:
    Account(const S<Node> &node, const Common &common) :
        node_(node),
        boxer_(node->GetSecret(), common)
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

    cppcoro::task<void> Send(const Buffer &data) override {
        _assert(input_ != nullptr);
        co_return co_await input_->Send(data);
    }


    void Land(const Buffer &data) {
        Beam unboxed(data);
        Spawn([unboxed = std::move(unboxed), self = shared_from_this()]() -> cppcoro::task<void> {
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
                    auto socket(std::make_unique<Socket>());
                    co_await socket->_(host, port);
                    self->outputs_[tag] = std::make_unique<Output>(self, tag, std::move(socket));
                    co_await self->Send(Tie(nonce));


                } else if (command == OfferTag) {
                    const auto [handle] = Take<TagSize>(args);
                    auto outstanding(std::make_shared<Outstanding>());
                    self->outstandings_[handle] = outstanding;
                    auto offer(co_await outstanding->Offer());
                    co_await self->Send(Tie(nonce, Beam(offer)));

                } else if (command == NegotiateTag) {
                    const auto [handle, answer] = Take<TagSize, 0>(args);
                    auto outstanding(self->outstandings_.find(handle));
                    _assert(outstanding != self->outstandings_.end());
                    co_await outstanding->second->Negotiate(answer.str());
                    co_await self->Send(Tie(nonce));

                } else if (command == ChannelTag) {
                    const auto [handle, tag] = Take<TagSize, TagSize>(args);
                    auto outstanding(self->outstandings_.find(handle));
                    _assert(outstanding != self->outstandings_.end());
                    auto channel(std::make_unique<Channel>(outstanding->second));
                    self->outputs_[tag] = std::make_unique<Output>(self, tag, std::move(channel));
                    co_await self->Send(Tie(nonce));

                } else if (command == CancelTag) {
                    const auto [handle] = Take<TagSize>(args);
                    self->outstandings_.erase(handle);
                    co_await self->Send(Tie(nonce));


                } else if (command == AnswerTag) {
                    const auto [offer] = Take<0>(args);
                    auto answer(co_await self->node_->Respond(offer.str()));
                    co_await self->Send(Tie(nonce, Beam(answer)));

                } else _assert(false);
            }
        }());
    }
};

class Input :
    public std::enable_shared_from_this<Input>,
    public Pipe
{
  private:
    S<Pipe> path_;
    Tag tag_;
    S<Account> account_;

  public:
    Input(const S<Pipe> &path, const Tag &tag, const S<Account> &account) :
        path_(path),
        tag_(tag),
        account_(account)
    {
        account_->Associate(this);
    }

    ~Input() {
        account_->Dissociate(this);
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        co_return co_await path_->Send(Tie(tag_, data));
    }

    void Land(const Buffer &data) {
        account_->Land(data);
    }
};

void Node::Land(const S<Pipe> &path, const Buffer &data) {
    if (data.empty()) {
        for (const auto &[key, value] : inputs_)
            if (key.first == path.get())
                inputs_.erase(key);
    } else {
        auto [tag, command, rest] = Take<TagSize, TagSize, 0>(data);
        auto key(std::make_pair(path.get(), tag));

        if (false) {

        } else if (command == AssociateTag) {
            auto [common] = Take<Common::Size>(rest);
            auto &account(accounts_[common]);
            if (!account)
                account = std::make_shared<Account>(shared_from_this(), common);
            auto input(std::make_shared<Input>(path, tag, account));
            inputs_[key] = input;

        } else if (command == DissociateTag) {
            /*auto [] =*/ Take<>(rest);
            inputs_.erase(key);

        } else if (command == DeliverTag) {
            auto [boxed] = Take<0>(rest);
            auto input(inputs_.find(key));
            _assert(input != inputs_.end());
            input->second->Land(boxed);

        } else _assert(false);
    }
}

class Conduit :
    public Pipe
{
  private:
    S<Node> node_;
    Sink<Channel> sink_;

  public:
    S<Pipe> self_;

  public:
    Conduit(const S<Node> &node, U<Channel> channel) :
        node_(node),
        sink_(std::move(channel), [this](const Buffer &data) {
            node_->Land(self_, data);
            if (data.empty())
                self_.reset();
        })
    {
        _trace();
    }

    virtual ~Conduit() {
        _trace();
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        co_return co_await sink_.Send(data);
    }
};

class Client :
    public Connection
{
  private:
    S<Node> node_;

  public:
    Client(S<Node> node) :
        node_(std::move(node))
    {
    }

    ~Client() {
        _trace();
    }

    void OnChannel(U<Channel> channel) override {
        auto conduit(std::make_shared<Conduit>(node_, std::move(channel)));
        conduit->self_ = conduit;
        // XXX: also automatically remove this after some timeout
        node_->clients_.erase(shared_from_this());
    }
};

cppcoro::task<std::string> Node::Respond(const std::string &offer) {
    auto client(std::make_shared<Client>(shared_from_this()));
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
        auto answer(cppcoro::sync_wait(internal->node_->Respond(request->offer_)));

        std::cerr << std::endl;
        std::cerr << "^^^^^^^^^^^^^^^^" << std::endl;
        std::cerr << request->offer_ << std::endl;
        std::cerr << "================" << std::endl;
        std::cerr << answer << std::endl;
        std::cerr << "vvvvvvvvvvvvvvvv" << std::endl;
        std::cerr << std::endl;

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
    vfprintf(stderr, format, args);
}

int main() {
    //orc::Ethereum();

    /*cppcoro::sync_wait([]() -> cppcoro::task<void> {
        auto socket(std::make_unique<orc::Socket>());
        co_await socket->_("localhost", "9090");
        co_await socket->Send(orc::Beam("Hello\n"));
        orc::Sink sink(std::move(socket), [](const orc::Buffer &data) {});
        _trace();
        //co_await orc::Request(std::move(socket), "POST", {"http", "localhost", "9090", "/"}, {}, "wow");
        co_await orc::Request("POST", {"http", "localhost", "9090", "/"}, {}, "wow");
        _trace();
    }());
    _trace();
    return 0;*/

    orc::Block<4> block;
    orc::Hash hash(block);

    auto internal(new Internal{});
    internal->node_ = std::make_shared<orc::Node>();

    http_ = MHD_start_daemon(MHD_USE_SELECT_INTERNALLY | MHD_USE_DEBUG, 8080, NULL, NULL, &Respond, internal,
        MHD_OPTION_EXTERNAL_LOGGER, &LogMHD, NULL,
        MHD_OPTION_NOTIFY_COMPLETED, &Complete, internal,
        MHD_OPTION_NOTIFY_CONNECTION, &Connect, internal,
    MHD_OPTION_END);

    _assert(http_ != NULL);

    asio::signal_set signals(orc::Context(), SIGINT, SIGTERM);
    signals.async_wait([&](auto, auto) { orc::Context().stop(); });

    orc::Thread().join();
    return 0;
}
