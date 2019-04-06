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

#include <asio/experimental/co_spawn.hpp>
#include <asio/experimental/detached.hpp>

#include <asio/ip/tcp.hpp>

#include <asio/connect.hpp>
#include <asio/io_context.hpp>
#include <asio/signal_set.hpp>
#include <asio/write.hpp>

#include <asio.hpp>

#include <unistd.h>

#include <microhttpd.h>

#include "crypto.hpp"
//#include "ethereum.hpp"
#include "scope.hpp"
#include "shared.hpp"
#include "trace.hpp"
#include "webrtc.hpp"

#define _disused \
    __attribute__((__unused__))

template <typename Type_>
using awaitable = asio::experimental::awaitable<Type_, asio::io_context::executor_type>;

static asio::io_context io_context(1);


static std::set<std::shared_ptr<orc::Connection>> clients_;

namespace orc {

class Client;

class Account :
    public orc::Link
{
  private:
    Common common_;
    W<Pipe> input_;

    std::map<Tag, H<Pipe>> handles_;

  public:
    Account(const Common &common) :
        common_(common)
    {
    }

    void Associate(const H<Pipe> &input) {
        input_ = input;
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        if (auto input = input_.lock())
            return input->Send(data);
        else _assert(false);
    }

    void Land(const Buffer &data) {
        const auto &unboxed(data);
        auto [key, tag, args] = orc::Take<TagSize, TagSize, 0>(unboxed);
    }
};

class Input :
    public orc::Pipe
{
  private:
    H<Pipe> path_;
    Tag tag_;
    H<Account> account_;

  public:
    Input(const H<Pipe> &path, const Tag &tag, const H<Account> &account) :
        path_(path),
        tag_(tag),
        account_(account)
    {
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        return path_->Send(orc::Tie(tag_, data));
    }

    void Land(const Buffer &data) {
        account_->Land(data);
    }
};

class Node {
  private:
    std::map<Common, H<Account>> accounts_;

    typedef std::pair<Pipe *, Tag> Key_;
    std::map<Key_, H<Input>> inputs_;

  public:
    void Land(const H<Pipe> &path, const Buffer &data) {
_trace();
        if (data.size() == 0) {
            for (auto [key, value] : inputs_)
                if (key.first == path.get())
                    inputs_.erase(key);
        } else {
_trace();
            auto [command, tag, rest] = orc::Take<TagSize, TagSize, 0>(data);
            auto key(std::make_pair(path.get(), tag));

            if (false) {
            } else if (command == AssociateTag) {
_trace();
                auto [common] = orc::Take<Common::Size>(rest);
                auto &account(accounts_[common]);
_trace();
                if (!account)
                    account = std::make_shared<Account>(common);
_trace();
                auto input(std::make_shared<Input>(path, tag, account));
                inputs_[key] = input;
_trace();
                account->Associate(input);
            } else if (command == DissociateTag) {
_trace();
                /*auto [] =*/ orc::Take<>(rest);
                inputs_.erase(key);
_trace();
            } else if (command == DeliverTag) {
_trace();
                auto [boxed] = orc::Take<0>(rest);
                auto input(inputs_.find(key));
_trace();
                _assert(input != inputs_.end());
                input->second->Land(boxed);
_trace();
            }
        }
    }
};

/*
    std::unique_ptr<asio::ip::tcp::socket> socket_;
    bool failed_;

        if (failed_)
            return;
        if (data.size() == 0) {
            self_.reset();
            socket_->close();
        } else if (socket_) {
            Sequence sequence(data);
            socket_->send(sequence);
        } else {
            auto string(data.str());
            std::cerr << string << std::endl;
            auto colon(string.find(':'));
            _assert(colon != std::string::npos);
            auto host(string.substr(0, colon));
            auto port(string.substr(colon + 1));
            socket_ = std::make_unique<asio::ip::tcp::socket>(io_context);

            {
                asio::ip::tcp::resolver resolver(io_context);
                asio::ip::tcp::resolver::query query(host, port);

                try {
                    asio::connect(*socket_, resolver.resolve(query));
                } catch (const asio::system_error &e) {
                    cppcoro::sync_wait(Send(Null()));
                    failed_ = true;
                    return;
                }
            }

            asio::experimental::co_spawn(io_context, [self = self_]() -> awaitable<void> {
                auto token(co_await asio::experimental::this_coro::token());
                try {
                    for (;;) {
                        char data[1024];
                        size_t writ(co_await self->socket_->async_receive(asio::buffer(data), token));
                        cppcoro::sync_wait(self->Send(Beam(data, writ)));
                    }
                } catch (const asio::system_error &e) {
                    cppcoro::sync_wait(self->Send(Null()));
                }
            }, asio::experimental::detached);
        }
    }
*/

class Conduit :
    public std::enable_shared_from_this<Conduit>,
    public Sink
{
  public:
    H<Conduit> self_;

    Conduit(const H<Node> &node, const std::shared_ptr<Channel> &channel) :
        Sink([this, node](const Buffer &data) {
            node->Land(shared_from_this(), data);
        }, channel)
    {
        _trace();
    }

    virtual ~Conduit() {
        _trace();
    }
};

class Client :
    public Connection
{
  private:
    H<Node> node_;

  public:
    Client(const H<Node> &node) :
        node_(node)
    {
    }

    ~Client() {
        _trace();
    }

    void OnDataChannel(rtc::scoped_refptr<webrtc::DataChannelInterface> channel) override {
        auto client(shared_from_this());
        auto conduit(std::make_shared<Conduit>(node_, std::make_shared<Channel>(client, channel)));
        conduit->self_ = conduit;
        // XXX: also automatically remove this after some timeout
        clients_.erase(client);
    }
};

}


static MHD_Daemon *http_;

struct Internal {
    orc::H<orc::Node> node_;
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
        auto client(std::make_shared<orc::Client>(internal->node_));

        auto sdp(cppcoro::sync_wait([&]() -> cppcoro::task<std::string> {
            co_await client->Negotiate("offer", request->offer_);

            co_return co_await client->Negotiation(co_await [&]() -> cppcoro::task<webrtc::SessionDescriptionInterface *> {
                rtc::scoped_refptr<orc::CreateObserver> observer(new rtc::RefCountedObject<orc::CreateObserver>());
                webrtc::PeerConnectionInterface::RTCOfferAnswerOptions options;
                (*client)->CreateAnswer(observer, options);
                co_await *observer;
                co_return observer->description_;
            }());
        }()));

        clients_.insert(client);

        /*std::cerr << std::endl;
        std::cerr << "^^^^^^^^^^^^^^^^" << std::endl;
        std::cerr << request->offer_ << std::endl;
        std::cerr << "================" << std::endl;
        std::cerr << sdp << std::endl;
        std::cerr << "vvvvvvvvvvvvvvvv" << std::endl;
        std::cerr << std::endl;*/

        return Data(connection, "text/plain", sdp);
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

    asio::signal_set signals(io_context, SIGINT, SIGTERM);
    signals.async_wait([&](auto, auto) { io_context.stop(); });

    io_context.run();
_trace();
    return 0;
}
