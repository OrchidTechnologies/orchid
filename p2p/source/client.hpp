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

#include "http.hpp"
#include "secure.hpp"
#include "shared.hpp"
#include "task.hpp"
#include "trace.hpp"

namespace orc {

template <typename... Args_>
struct Delayed {
    std::function<task<void> (Args_...)> code_;
    U<Link> link_;
};

typedef Delayed<const std::string &, const std::string &> DelayedConnect;

class Remote;

class Origin {
  public:
    virtual task<S<Remote>> Hop(const std::string &server) = 0;

    virtual DelayedConnect Connect() = 0;

    task<std::string> Request(const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data);
};

class Remote :
    public std::enable_shared_from_this<Remote>,
    public Origin,
    public Router<Secure>
{
  public:
    Remote(U<Link> link) :
        Router(std::make_unique<Secure>(false, std::move(link), []() -> bool {
            return true;
        }))
    {
    }

    task<void> _(const Common &common) {
        co_return co_await (*this)->_();
    }

    virtual ~Remote() {
    }


    U<Route<Remote>> Path();
    task<Beam> Call(const Tag &command, const Buffer &data);

    task<S<Remote>> Hop(const std::string &server) override;
    DelayedConnect Connect() override;
};

class Local :
    public Origin
{
  public:
    virtual ~Local() {
    }

    task<S<Remote>> Hop(const std::string &server) override;
    DelayedConnect Connect() override;
};

S<Local> GetLocal();

task<S<Origin>> Setup();

}

#endif//ORCHID_CLIENT_HPP
