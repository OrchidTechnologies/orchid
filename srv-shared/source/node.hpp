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


#ifndef ORCHID_NODE_HPP
#define ORCHID_NODE_HPP

#include <mutex>
#include <vector>

#include "egress.hpp"
#include "jsonrpc.hpp"
#include "locator.hpp"
#include "server.hpp"

namespace orc {

class Node final {
  private:
    std::vector<std::string> ice_;

    Locator locator_;
    Address lottery_;

    S<Egress> egress_;

    std::mutex mutex_;
    std::map<std::string, W<Server>> servers_;

  public:
    Node(std::vector<std::string> ice, const std::string &rpc, Address lottery) :
        ice_(std::move(ice)),
        locator_(Locator::Parse(rpc)),
        lottery_(std::move(lottery))
    {
    }

    S<Egress> &Wire() {
        return egress_;
    }

    S<Server> Find(const std::string &fingerprint) {
        std::unique_lock<std::mutex> lock(mutex_);
        auto &cache(servers_[fingerprint]);
        if (auto server = cache.lock())
            return server;
        auto server(Make<Sink<Server>>(locator_, lottery_));
        server->Wire<Translator>(egress_);
        server->self_ = server;
        cache = server;
        return server;
    }

    void Run(asio::ip::address bind, uint16_t port, const std::string &path, const std::string &key, const std::string &chain, const std::string &params);
};

}

#endif//ORCHID_NODE_HPP
