/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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


#ifndef ORCHID_SFU_HPP
#define ORCHID_SFU_HPP

#include <map>
#include <thread>

#include "bonded.hpp"
#include "error.hpp"
#include "event.hpp"
#include "locked.hpp"
#include "notation.hpp"
#include "unique.hpp"

namespace orc {

// XXX: making this Bonded is such a cop-out

class Worker :
    public Valve,
    public Bonded
{
  private:
    std::thread thread_;
    Pipe<Buffer> *send_ = nullptr;

    struct Locked_ {
        uint64_t id_ = 0;
        std::map<decltype(id_), Transfer<boost::json::object>> transfers_;
    }; Locked<Locked_> locked_;

  protected:
    void Land(Pipe<Buffer> *pipe, const Buffer &data) override;
    void Stop() noexcept override;

  public:
    Worker() :
        Valve(typeid(*this).name())
    {
    }

    auto &Bond() {
        auto &bond(Bonded::Bond());
        if (send_ == nullptr)
            send_ = &bond;
        return bond;
    }

    static S<Worker> New();

    void Open(int rcfd, int wcfd, int rpfd, int wpfd);
    task<void> Shut() noexcept override;

    task<boost::json::object> Call(const std::string &method, boost::json::object internal, boost::json::object data = {});

    task<void> CreateRouter(const Unique &router);
};

}

#endif//ORCHID_SFU_HPP
