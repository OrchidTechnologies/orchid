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
    const uint64_t unique_ = ++Unique_;

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
  private:
    typedef Drain_ Drain;
    Drain_ *const drain_;

    cppcoro::async_manual_reset_event shut_;

  protected:
    Drain_ *Outer() {
        return drain_;
    }

    void Stop() {
        _assert(!shut_.is_set());
        shut_.set();
    }

  public:
    Pump(Drain_ *drain) :
        drain_(drain)
    {
    }

    virtual ~Pump() {
        if (Verbose)
            Log() << "##### " << unique_ << std::endl;
        _insist(shut_.is_set());
    }

    virtual task<void> Shut() {
        co_await shut_;
        co_await Schedule();
    }
};

class Link :
    public Pump<BufferDrain>,
    public BufferDrain
{
  protected:
    void Land(const Buffer &data) override {
        return Outer()->Land(data);
    }

    void Stop(const std::string &error = std::string()) override {
        Pump<BufferDrain>::Stop();
        return Outer()->Stop(error);
    }

  public:
    Link(BufferDrain *drain) :
        Pump<BufferDrain>(drain)
    {
    }
};

template <typename Inner_ = Link, typename Drain_ = BufferDrain>
class Sunk {
  protected:
    U<Inner_> inner_;

  public:
    virtual Drain_ *Gave() = 0;

    template <typename Type_>
    Type_ *Give(U<Type_> inner) {
        auto backup(inner.get());
        inner_ = std::move(inner);
        return backup;
    }

    template <typename Type_, typename... Args_>
    Type_ *Wire(Args_ &&...args) {
        return Give(std::make_unique<Type_>(Gave(), std::forward<Args_>(args)...));
    }
};

template <typename Base_, typename Inner_ = Link, typename Drain_ = BufferDrain>
class Sink final :
    public Base_,
    public Sunk<Inner_, Drain_>
{
  protected:
    Inner_ *Inner() override {
        auto inner(this->inner_.get());
        _insist(inner != nullptr);
        return inner;
    }

    Drain_ *Gave() override {
        return this;
    }

  public:
    using Base_::Base_;
};

template <typename Link_>
class Router :
    public Pipe,
    public BufferDrain
{
    template <typename Router_>
    friend class Route;

  private:
    std::map<Tag, BufferDrain *> routes_;

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
    virtual ~Router() {
        _insist(routes_.empty());
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
    Route(BufferDrain *drain, const S<Router_> router) :
        Link(drain),
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
