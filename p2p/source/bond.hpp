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

#include "link.hpp"

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

        void Stop(const std::string &error) override {
            Valve::Stop();
            bonded_->bondings_.erase(this);
        }

      public:
        Bonding(Bonded *bonded) :
            bonded_(bonded)
        {
        }

        task<void> Shut() override {
            co_await Inner()->Shut();
            co_await Valve::Shut();
        }

        task<void> Send(const Buffer &data) override {
            co_return co_await Inner()->Send(data);
        }
    };

    std::map<Bonding *, U<Bonding>> bondings_;

  protected:
    virtual void Land(Pipe<Buffer> *pipe, const Buffer &data) = 0;

  public:
    Sink<Bonding> *Bond() {
        // XXX: this is non-obviously incorrect
        auto bonding(std::make_unique<Sink<Bonding>>(this));
        const auto backup(bonding.get());
        bondings_.emplace(backup, std::move(bonding));
        return backup;
    }

    task<void> Shut() override {
        for (auto current(bondings_.begin()); current != bondings_.end(); ) {
            auto next(current);
            ++next;
            co_await current->second->Shut();
            current = next;
        }

        co_await Valve::Shut();
    }

    task<void> Send(const Buffer &data) {
        const auto bonding(bondings_.begin());
        if (bonding != bondings_.end())
            co_await bonding->second->Send(data);
    }
};

}

#endif//ORCHID_BOND_HPP
