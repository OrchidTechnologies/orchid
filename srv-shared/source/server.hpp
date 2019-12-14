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

#include <rtc_base/rtc_certificate.h>

#include "bond.hpp"
#include "jsonrpc.hpp"
#include "link.hpp"
#include "locked.hpp"
#include "nest.hpp"
#include "shared.hpp"
#include "task.hpp"

namespace orc {

class Cashier;

class Server :
    public Bonded,
    protected Pipe<Buffer>,
    public BufferDrain
{
  public:
    S<Server> self_;
  private:
    const rtc::scoped_refptr<rtc::RTCCertificate> local_;

    const S<Origin> origin_;
    const S<Cashier> cashier_;

    Nest nest_;

    static const size_t horizon_ = 10;

    struct Locked_ {
        uint64_t serial_ = 0;
        Float balance_ = 0;

        std::map<Bytes32, std::pair<Bytes32, uint256_t>> reveals_;
        decltype(reveals_.end()) commit_ = reveals_.end();

        uint256_t issued_ = 0;
        std::set<std::tuple<uint256_t, Bytes32, Address>> nonces_;
    }; Locked<Locked_> locked_;

    bool Bill(const Buffer &data, bool force);

    task<void> Send(Pipe *pipe, const Buffer &data, bool force);
    void Send(Pipe *pipe, const Buffer &data);

    task<void> Send(const Buffer &data) override;

    void Commit(const Lock<Locked_> &locked);

    task<void> Invoice(Pipe<Buffer> *pipe, const Socket &destination, const Bytes32 &id, uint64_t serial, const Float &balance, const Bytes32 &commit);
    task<void> Invoice(Pipe<Buffer> *pipe, const Socket &destination, const Bytes32 &id);

    task<void> Submit(Pipe<Buffer> *pipe, const Bytes32 &id, const Buffer &data);

  protected:
    virtual Pump<Buffer> *Inner() = 0;

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
