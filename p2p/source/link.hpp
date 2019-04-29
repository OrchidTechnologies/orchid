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
    virtual ~Pipe() {}
    virtual task<void> Send(const Buffer &data) = 0;
};

typedef std::function<void (const Buffer &data)> Drain;

class Link :
    public Pipe
{
    template <typename Type_>
    friend class Sink;

  public:
    static uint64_t Unique_;
    uint64_t unique_ = ++Unique_;

  private:
    Drain drain_;

  public:
    Link() {
    }

    virtual ~Link() {
        if (drain_ != nullptr)
            std::terminate();
    }

  protected:
    void Land(const Buffer &data = Nothing()) {
        _assert(drain_ != nullptr);
        drain_(data);
    }
};

template <typename Type_ = Link>
class Sink {
  private:
    U<Type_> link_;

  public:
    Sink(Drain drain, U<Type_> link) :
        link_(std::move(link))
    {
        _assert(link_);
        _assert(link_->drain_ == nullptr);
        link_->drain_ = std::move(drain);
    }

    ~Sink() {
        if (link_)
            link_->drain_ = nullptr;
    }

    task<void> Send(const Buffer &data) {
        _assert(link_);
        co_return co_await link_->Send(data);
    }

    U<Type_> Move() {
        _assert(link_);
        link_->drain_ = nullptr;
        return std::move(link_);
    }

    Type_ *operator ->() {
        return link_.get();
    }
};


template <typename Link_>
class Router :
    public Pipe
{
    template <typename Router_>
    friend class Route;

  private:
    std::map<Tag, Drain> routes_;
    Sink<Link_> sink_;

  public:
    Router(U<Link_> link) :
        sink_([this](const Buffer &data) {
            if (data.empty())
                for (const auto &[tag, drain] : routes_)
                    drain(data);
            else {
                auto [tag, rest] = Take<TagSize, 0>(data);
                auto route(routes_.find(tag));
                _assert(route != routes_.end());
                route->second(rest);
            }
        }, std::move(link))
    {
    }

    virtual ~Router() {
        if (!routes_.empty())
            std::terminate();
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await sink_.Send(data);
    }

    Link_ *operator ->() {
        return sink_.operator ->();
    }

    U<Link_> Move() {
        return sink_.Move();
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
            for (;;) {
                auto tag(NewTag());
                if (router_->routes_.emplace(tag, [this](const Buffer &data) {
                    Land(data);
                }).second)
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

    const S<Router_> &operator ->() {
        return router_;
    }
};

}

#endif//ORCHID_LINK_HPP
