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


#ifndef ORCHID_RETRY_HPP
#define ORCHID_RETRY_HPP

#include "nest.hpp"
#include "sleep.hpp"
#include "tube.hpp"

namespace orc {

template <typename Code_>
class Retry final :
    public Link<Buffer>
{
  private:
    Code_ code_;
    U<Pump<Buffer>> tube_;
    Nest nest_;

    void Close(U<Pump<Buffer>> &&tube) noexcept {
        if (tube != nullptr)
            Spawn([tube = std::move(tube)]() noexcept -> task<void> {
                co_await tube->Shut();
            });
    }

  protected:
    void Land(const Buffer &data) override {
        return Link::Land(data);
    }

    void Stop(const std::string &error) noexcept override {
        Close(std::move(tube_));
        if (!Open())
            Link::Stop(error);
    }

  public:
    Retry(BufferDrain &drain, Code_ code) :
        Link<Buffer>(drain),
        code_(std::move(code))
    {
        type_ = typeid(*this).name();
    }

    bool Open() noexcept {
        return nest_.Hatch([&]() noexcept { return [&]() noexcept -> task<void> {
            auto tube(std::make_unique<BufferSink<Tube>>(*this));
            if (orc_ignore({ co_await code_(*tube); })) {
                if (!tube->Wired())
                    tube->template Wire<Cap>();
                Close(std::move(tube));
            } else
                tube_ = std::move(tube);
        }; });
    }

    task<void> Shut() noexcept override {
        co_await nest_.Shut();
        Close(std::move(tube_));
        co_await Link::Shut();
    }

    task<void> Send(const Buffer &data) override {
        if (tube_ != nullptr)
            co_await tube_->Send(data);
    }
};

}

#endif//ORCHID_RETRY_HPP
