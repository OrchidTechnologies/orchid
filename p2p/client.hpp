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
#include "task.hpp"
#include "trace.hpp"

namespace orc {

class Remote :
    public Router
{
  private:

  public:
    Remote(U<Link> link) :
        Router(std::move(link))
    {
    }
};

class Connector {
  public:
    virtual task<S<Remote>> Hop(const std::string &server) = 0;
    virtual task<U<Link>> Connect(const std::string &host, const std::string &port) = 0;
};

class Account$ :
    public std::enable_shared_from_this<Account$>,
    public Router,
    public Connector
{
  private:

  public:
    Account$(const S<Remote> &remote) :
        Router(std::make_unique<Route<Remote>>(remote))
    {
    }

    task<void> _(const Common &common) {
        co_await Router::Send(Tie(AssociateTag, common));
    }

    ~Account$() {
        Task([pipe = Move()]() -> task<void> {
            co_await pipe->Send(Tie(DissociateTag));
        });
    }

    task<void> Send(const Buffer &data) override {
        co_await Router::Send(Tie(DeliverTag, data));
    }


    task<Beam> Call(const Tag &command, const Buffer &data);

    task<S<Remote>> Hop(const std::string &server) override;
    task<U<Link>> Connect(const std::string &host, const std::string &port) override;
};

task<S<Remote>> Hop(const std::string &server);

task<U<Link>> Setup(const std::string &host, const std::string &port);

}

#endif//ORCHID_CLIENT_HPP
