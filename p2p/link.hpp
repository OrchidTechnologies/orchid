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
using H = std::shared_ptr<Type_>;

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
        _assert(drain_ == nullptr);
    }

  protected:
    void Land(const Buffer &data = Null()) {
        std::lock_guard<std::mutex> lock(mutex_);
        _assert(drain_ != nullptr);
        drain_(data);
    }
};

class Sink :
    public Pipe
{
  private:
    const H<Link> link_;

  public:
    template <typename... Args_>
    Sink(Drain drain, Args_ &&...args) :
        link_(std::forward<Args_>(args)...)
    {
        std::lock_guard<std::mutex> lock(link_->mutex_);
        _assert(link_->drain_ == nullptr);
        link_->drain_ = std::move(drain);
    }

    ~Sink() {
        std::lock_guard<std::mutex> lock(link_->mutex_);
        link_->drain_ = nullptr;
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        return link_->Send(data);
    }
};


class Router :
    public Sink
{
    friend class Route;

  private:
    std::map<Tag, Drain> routes_;

  public:
    Router(const H<Link> &link) :
        Sink([this](const Buffer &data) {
            auto string(data.str());
            _assert(string.size() > TagSize);
            auto tag(string.substr(0, TagSize));
            auto route(routes_.find(tag));
            _assert(route != routes_.end());
            route->second(Beam(string.substr(TagSize)));
        }, link)
    {
    }
};

class Route {
  protected:
    const H<Router> router_;

  public:
    const Tag tag_;

  public:
    Route(Drain drain, const H<Router> &router) :
        router_(router),
        tag_(NewTag())
    {
        router_->routes_.emplace(tag_, std::move(drain));
    }

    ~Route() {
        router_->routes_.erase(tag_);
    }
};

/*
class Route :
    public Link
{
  public:
    const H<Router> router_;
    const Tag tag_;

  public:
    virtual ~Route() {
        _assert(router_->routes_.erase(tag_) == 1);
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        std::make_tuple(tag_, tag_);
        return router_->link_->Send(orc::Cat(tag_, tag_));//data));
    }
};
*/

/*class Tunnel :
    public Link
{
  private:
    const H<Link> link_;
    const Tag tag_;

  public:
    cppcoro::task<void> Send(const Buffer &data) override;
};*/

/*class Bridge {
  private:
    H<Route> route_;
    std::map<Tag, H<Destination>> tunnels_;
  public:
    Bridge(const H<Link> &link);
    virtual ~Bridge() {}
    cppcoro::task<H<Tunnel>> Connect(const std::string &host, const std::string &port);
};*/


}

#endif//ORCHID_LINK_HPP
