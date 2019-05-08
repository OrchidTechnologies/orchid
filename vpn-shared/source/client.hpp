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
#include "task.hpp"
#include "trace.hpp"

namespace orc {

class Remote;

class Origin {
  public:
    virtual task<void> Hop(Sunk<> *sunk, const std::string &server) = 0;

    virtual task<void> Connect(Sunk<> *sunk, const std::string &host, const std::string &port) = 0;

    task<std::string> Request(const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data);
};

class Remote :
    public std::enable_shared_from_this<Remote>,
    public Origin,
    public Router<Secure>
{
  private:
    const Common common_;

  protected:
    virtual Secure *Inner() = 0;

  public:
    Remote(Common common) :
        common_(std::move(common))
    {
    }

    task<void> _() {
        co_return co_await Inner()->_();
    }


    task<void> Send(const Buffer &data) {
        co_return co_await Inner()->Send(data);
    }


    task<void> Swing(Sunk<Secure> *sunk, const S<Origin> &origin, const std::string &server);

    U<Route<Remote>> Path(BufferDrain *drain);
    task<Beam> Call(const Tag &command, const Buffer &data);

    task<void> Hop(Sunk<> *sunk, const std::string &server) override;
    task<void> Connect(Sunk<> *sunk, const std::string &host, const std::string &port) override;
};

class Local final :
    public Origin
{
  public:
    virtual ~Local() {
    }

    task<void> Hop(Sunk<> *sunk, const std::string &server) override;
    task<void> Connect(Sunk<> *sunk, const std::string &host, const std::string &port) override;
};

S<Local> GetLocal();

task<S<Origin>> Setup();

}

#endif//ORCHID_CLIENT_HPP
