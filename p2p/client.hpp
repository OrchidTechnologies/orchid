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


#ifndef ORCHID_CLIENT_HPP
#define ORCHID_CLIENT_HPP

#include "shared.hpp"
#include "spawn.hpp"

namespace orc {

class Remote :
    public Router
{
  private:

  public:
    Remote(const H<Link> &link) :
        Router(link)
    {
    }
};

class Local :
    public Link,
    public Route
{
  private:
    Common common_;

  public:
    Local(const H<Remote> &router, const Common &common) :
        Route([this](const Buffer &data) {
            Land(data);
        }, router),
        common_(common)
    {
    }

    ~Local() {
        Spawn([pipe = router_, tag = tag_]() -> cppcoro::task<void> {
            co_await pipe->Send(Tie(DissociateTag, tag));
        }());
    }

    cppcoro::task<void> _() {
        co_await router_->Send(Tie(AssociateTag, tag_, common_));
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        co_await router_->Send(Tie(DeliverTag, tag_, data));
    }


    cppcoro::task<Beam> Request(const Tag &command, const Buffer &data);

    cppcoro::task<H<Link>> Connect(const std::string &host, const std::string &port);
};

cppcoro::task<H<Remote>> Direct(const std::string &server);

cppcoro::task<H<Link>> Setup(const std::string &host, const std::string &port);

}

#endif//ORCHID_CLIENT_HPP
