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


#ifndef ORCHID_BOND_HPP
#define ORCHID_BOND_HPP

#include <set>

#include <cppcoro/when_all.hpp>

#include "link.hpp"
#include "locked.hpp"

namespace orc {

class Bonded :
    public Valve
{
  private:
    class Bonding :
        public Valve,
        public Pipe<Buffer>,
        public BufferDrain
    {
      private:
        Bonded *const bonded_;

      protected:
        virtual Pump<Buffer> *Inner() = 0;

        void Land(const Buffer &data) override {
            return bonded_->Land(this, data);
        }

        void Stop(const std::string &error) noexcept override {
            bonded_->Stop(this);
            Valve::Stop();
        }

      public:
        Bonding(Bonded *bonded) :
            bonded_(bonded)
        {
        }

        task<void> Shut() noexcept override {
            co_await Inner()->Shut();
            co_await Valve::Shut();
        }

        task<void> Send(const Buffer &data) override {
            co_return co_await Inner()->Send(data);
        }
    };

    struct Locked_ {
        std::map<Bonding *, U<Bonding>> bondings_;
    }; Locked<Locked_> locked_;

  protected:
    virtual void Land(Pipe<Buffer> *pipe, const Buffer &data) = 0;

    void Stop(Bonding *bonding) {
        const auto locked(locked_());
        const auto iterator(locked->bondings_.find(bonding));
        Spawn([bonding = std::move(iterator->second)]() noexcept -> task<void> {
            co_await bonding->Shut();
        });
        locked->bondings_.erase(iterator);
    }

  public:
    Sink<Bonding> *Bond() {
        // XXX: this is non-obviously incorrect
        const auto locked(locked_());
        auto bonding(std::make_unique<Sink<Bonding>>(this));
        const auto backup(bonding.get());
        locked->bondings_.emplace(backup, std::move(bonding));
        return backup;
    }

    Bonding *Find() {
        // XXX: this lock isn't sufficient
        const auto locked(locked_());
        const auto bonding(locked->bondings_.begin());
        if (bonding == locked->bondings_.end())
            return nullptr;
        return bonding->first;
    }

    task<void> Shut() noexcept override {
        std::vector<task<void>> shuts;
        { const auto locked(locked_());
            for (const auto &bonding : locked->bondings_)
                shuts.emplace_back(bonding.second->Shut()); }
        co_await cppcoro::when_all(std::move(shuts));
        orc_insist(locked_()->bondings_.empty());
        co_await Valve::Shut();
    }

    task<void> Send(const Buffer &data) {
        if (const auto bonding = Find())
            co_await bonding->Send(data);
    }
};

}

#endif//ORCHID_BOND_HPP
