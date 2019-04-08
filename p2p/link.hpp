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

#include <cppcoro/task.hpp>

#include "buffer.hpp"
#include "crypto.hpp"
#include "error.hpp"

namespace orc {


template <typename Type_>
using U = std::unique_ptr<Type_>;

template <typename Type_>
using S = std::shared_ptr<Type_>;

template <typename Type_>
using W = std::weak_ptr<Type_>;


typedef Block<sizeof(uint32_t)> Tag;
static const size_t TagSize = sizeof(uint32_t);
inline Tag NewTag() {
    return Random<TagSize>();
}

class Pipe {
  public:
    virtual ~Pipe() {}
    virtual cppcoro::task<void> Send(const Buffer &data) = 0;
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
    std::mutex mutex_;
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
        std::lock_guard<std::mutex> lock(mutex_);
        _assert(drain_ != nullptr);
        drain_(data);
    }
};

template <typename Type_ = Link>
class Sink {
  private:
    U<Type_> link_;

  public:
    Sink(U<Type_> link, Drain drain) :
        link_(std::move(link))
    {
        _assert(link_);
        std::lock_guard<std::mutex> lock(link_->mutex_);
        _assert(link_->drain_ == nullptr);
        link_->drain_ = std::move(drain);
    }

    ~Sink() {
        if (link_) {
            std::lock_guard<std::mutex> lock(link_->mutex_);
            link_->drain_ = nullptr;
        }
    }

    cppcoro::task<void> Send(const Buffer &data) {
        _assert(link_);
        co_return co_await link_->Send(data);
    }

    U<Type_> Move() {
        _assert(link_);
        std::lock_guard<std::mutex> lock(link_->mutex_);
        link_->drain_ = nullptr;
        return std::move(link_);
    }

    Type_ *operator ->() {
        return link_.get();
    }
};


class Router :
    public Pipe
{
    template <typename Type_>
    friend class Route;

  private:
    std::map<Tag, Drain> routes_;
    Sink<> sink_;

  public:
    Router(U<Link> link) :
        sink_(std::move(link), [this](const Buffer &data) {
            if (data.empty())
                for (const auto &[tag, drain] : routes_)
                    drain(data);
            else {
                auto [tag, rest] = Take<TagSize, 0>(data);
                auto route(routes_.find(tag));
                _assert(route != routes_.end());
                route->second(rest);
            }
        })
    {
    }

    ~Router() {
        if (!routes_.empty())
            std::terminate();
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        co_return co_await sink_.Send(data);
    }

    U<Link> Move() {
        return sink_.Move();
    }
};

template <typename Type_>
class Route :
    public Link
{
  public:
    const S<Type_> router_;
    const Tag tag_;

  public:
    Route(const S<Type_> router) :
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

    cppcoro::task<void> Send(const Buffer &data) override {
        co_return co_await router_->Send(Tie(tag_, data));
    }

    Type_ *operator ->() {
        return router_.get();
    }
};

}

#endif//ORCHID_LINK_HPP
