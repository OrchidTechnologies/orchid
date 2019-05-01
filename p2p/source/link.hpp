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


#ifndef ORCHID_LINK_HPP
#define ORCHID_LINK_HPP

#include <functional>
#include <map>
#include <set>

#include <cppcoro/async_manual_reset_event.hpp>

#include "buffer.hpp"
#include "crypto.hpp"
#include "error.hpp"
#include "shared.hpp"
#include "task.hpp"

namespace orc {

typedef Block<sizeof(uint32_t)> Tag;
static const size_t TagSize = sizeof(uint32_t);
inline Tag NewTag() {
    return Random<TagSize>();
}

class Pipe {
  public:
    static uint64_t Unique_;
    uint64_t unique_ = ++Unique_;

    static void Insert(Pipe *pipe);
    static void Remove(Pipe *pipe);

  public:
    Pipe() {
        Insert(this);
    }

    virtual ~Pipe() {
        Remove(this);
    }

    virtual task<void> Send(const Buffer &data) = 0;
};

template <typename Type_>
class Drain {
  public:
    virtual void Land(Type_ data) = 0;
    virtual void Stop(const std::string &error = std::string()) = 0;
};

using BufferDrain = Drain<const Buffer &>;

template <typename Drain_>
class Pump :
    public Pipe
{
    template <typename Type_>
    friend class Sink;

  private:
    typedef Drain_ Drain;
    Drain_ *drain_;

    cppcoro::async_manual_reset_event shut_;

  protected:
    Drain_ *Use() {
        _assert(drain_ != nullptr);
        return drain_;
    }

    void Stop() {
        _assert(!shut_.is_set());
        shut_.set();
    }

  public:
    Pump() :
        drain_(nullptr)
    {
    }

    virtual ~Pump() {
        Log() << "##### " << unique_ << std::endl;
        _insist(drain_ == nullptr);
        _insist(shut_.is_set());
    }

    virtual task<void> Shut() {
        co_await shut_;
        co_await Schedule();
    }
};

class Link :
    public Pump<BufferDrain>,
    protected BufferDrain
{
  protected:
    void Land(const Buffer &data) override {
        return Use()->Land(data);
    }

    void Stop(const std::string &error = std::string()) override {
        Pump<BufferDrain>::Stop();
        return Use()->Stop(error);
    }
};

template <typename Link_>
class Sink {
  private:
    U<Link_> link_;

  public:
    Sink(decltype(link_->drain_) drain, U<Link_> link) :
        link_(std::move(link))
    {
        _assert(link_);
        _assert(link_->drain_ == nullptr);
        link_->drain_ = drain;
    }

    /*Sink(Sink &&sink) :
        link_(std::move(sink.link_))
    {
    }*/

    ~Sink() {
        if (link_)
            link_->drain_ = nullptr;
    }

    // XXX: just inherit from U<Link_>

    Link_ *operator ->() {
        return link_.get();
    }

    Link_ &operator *() {
        return *link_;
    }

    Link_ *get() {
        return link_.get();
    }
};


template <typename Link_>
class Router :
    public Pipe,
    protected BufferDrain
{
    template <typename Router_>
    friend class Route;

  private:
    std::map<Tag, BufferDrain *> routes_;
    Sink<Link_> sink_;

  protected:
    void Land(const Buffer &data) override {
        auto [tag, rest] = Take<TagSize, 0>(data);
        auto route(routes_.find(tag));
        _assert(route != routes_.end());
        route->second->Land(rest);
    }

    void Stop(const std::string &error) override {
        for (const auto &[tag, drain] : routes_)
            drain->Stop(error);
    }

  public:
    Router(U<Link_> link) :
        sink_(this, std::move(link))
    {
    }

    virtual ~Router() {
        _insist(routes_.empty());
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await sink_->Send(data);
    }

    Link_ *operator ->() {
        return sink_.operator ->();
    }
};

template <typename Router_>
class Route final :
    public Link
{
  public:
    const S<Router_> router_;
    const Tag tag_;

  public:
    Route(const S<Router_> router) :
        router_(router),
        tag_([this]() {
            BufferDrain *drain(this);
            for (;;) {
                auto tag(NewTag());
                if (router_->routes_.emplace(tag, drain).second)
                    return tag;
            }
        }())
    {
    }

    ~Route() {
        router_->routes_.erase(tag_);
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await router_->Send(Tie(tag_, data));
    }

    void Stop(const std::string &error = std::string()) override {
        Link::Stop(error);
    }

    const S<Router_> &operator ->() {
        return router_;
    }
};

}

#endif//ORCHID_LINK_HPP
