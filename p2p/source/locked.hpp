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

#ifndef ORCHID_LOCKED_HPP
#define ORCHID_LOCKED_HPP

#include <mutex>

namespace orc {

template <typename Locked_>
class Lock :
    public std::unique_lock<std::mutex>
{
  private:
    Locked_ &locked_;

  public:
    Lock(std::mutex &mutex, Locked_ &locked) :
        std::unique_lock<std::mutex>(mutex),
        locked_(locked)
    {
    }

    Lock(const Lock<Locked_> &lock) = delete;
    Lock(Lock<Locked_> &&lock) noexcept = default;

    Locked_ &operator *() const {
        return locked_;
    }

    Locked_ *operator ->() const {
        return &locked_;
    }
};

template <typename Locked_>
class Locked {
  private:
    mutable std::mutex mutex_;
    Locked_ locked_;

  public:
    Locked() = default;
    Locked(const Locked<Locked_> &lock) = delete;

    Lock<Locked_> operator ()() {
        return {mutex_, locked_};
    }

    Lock<const Locked_> operator ()() const {
        return {mutex_, locked_};
    }
};

}

#endif//ORCHID_LOCKED_HPP
