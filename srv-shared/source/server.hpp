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


#ifndef ORCHID_SERVER_HPP
#define ORCHID_SERVER_HPP

#include <map>
#include <set>

#include "bond.hpp"
#include "cashier.hpp"
#include "endpoint.hpp"
#include "link.hpp"
#include "jsonrpc.hpp"
#include "shared.hpp"
#include "task.hpp"

namespace orc {

class Server :
    public Bonded,
    protected Pipe<Buffer>,
    public BufferDrain
{
  public:
    S<Server> self_;
  private:
    const S<Origin> origin_;
    const S<Cashier> cashier_;
    uint256_t balance_;

    std::mutex mutex_;

    std::map<Bytes32, std::pair<Bytes32, uint256_t>> reveals_;
    decltype(reveals_.end()) commit_ = reveals_.end();

    std::set<std::tuple<uint256_t, Address, Bytes32>> tickets_;

    void Bill(Pipe *pipe, const Buffer &data);
    task<void> Send(const Buffer &data) override;

    void Commit();

    task<void> Invoice(Pipe<Buffer> *pipe, const Socket &destination, const Bytes32 &id, const Bytes32 &commit);
    task<void> Invoice(Pipe<Buffer> *pipe, const Socket &destination, const Bytes32 &id = Zero<32>());

  protected:
    virtual Pump *Inner() = 0;

    void Land(Pipe<Buffer> *pipe, const Buffer &data) override;

    void Land(const Buffer &data) override;
    void Stop(const std::string &error) override;

  public:
    Server(S<Origin> origin, S<Cashier> cashier);

    task<void> Open(Pipe<Buffer> *pipe);
    task<void> Shut() override;

    task<std::string> Respond(const std::string &offer, std::vector<std::string> ice);
};

std::string Filter(bool answer, const std::string &serialized);

}

#endif//ORCHID_SERVER_HPP
