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


#ifndef ORCHID_CACHE_HPP
#define ORCHID_CACHE_HPP

#include <map>
#include <mutex>
#include <tuple>

#include "error.hpp"

namespace orc {

template <typename Type_, typename Value_, typename Args_, Type_ (*Code_)(Value_, Args_)>
class Cache {
  private:
    Value_ value_;

    std::mutex mutex_;
    std::map<Args_, Type_> cache_;

  public:
    Cache(Value_ &value) :
        value_(value)
    {
    }

    Type_ &operator ()(const Args_ &args) {
        const std::unique_lock<std::mutex> lock(mutex_);
        const auto &cache(cache_.find(args));
        if (cache != cache_.end())
            return cache->second;
        const auto emplaced(cache_.try_emplace(args, Code_(value_, args)));
        orc_insist(emplaced.second);
        return emplaced.first->second;
    }
};

}

#endif//ORCHID_CACHE_HPP
