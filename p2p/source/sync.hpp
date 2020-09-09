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


#ifndef ORCHID_SYNC_HPP
#define ORCHID_SYNC_HPP

#include "baton.hpp"
#include "link.hpp"
#include "reader.hpp"

namespace orc {

class Sync :
    public Link<Buffer>
{
  protected:
    virtual size_t Read_(const Mutables &buffers) = 0;
    virtual size_t Send_(const Buffer &data) = 0;

  public:
    using Link<Buffer>::Link;

    size_t Read(const Mutables &buffers) {
        size_t writ;
        try {
            writ = Read_(buffers);
        } catch (const asio::system_error &error) {
            const auto code(error.code());
            if (code == asio::error::eof)
                return 0;
            orc_adapt(error);
        }

        return writ;
    }

    void Open() {
        std::thread([this]() {
            Beam beam(2048);
            for (;;) {
                size_t writ;
                try {
                    writ = Read(asio::buffer(beam.data(), beam.size()));
                } catch (const std::exception &error) {
                    const auto what(error.what());
                    orc_insist(what != nullptr);
                    orc_insist(*what != '\0');
                    Link::Stop(what);
                    break;
                }

                if (writ == 0) {
                    Link::Stop();
                    break;
                }

                const auto subset(beam.subset(0, writ));
                Link::Land(subset);
            }
        }).detach();
    }

    task<void> Send(const Buffer &data) override {
        size_t writ;
        try {
            writ = Send_(data);
        } catch (const asio::system_error &error) {
            orc_adapt(error);
        }
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");

        co_return;
    }
};

template <typename Sync_>
class SyncConnection :
    public Sync
{
  protected:
    Sync_ sync_;

    size_t Read_(const Mutables &buffers) override {
        return sync_.receive(buffers);
    }

    size_t Send_(const Buffer &data) override {
        return sync_.send(Sequence(data));
    }

  public:
    template <typename... Args_>
    SyncConnection(BufferDrain &drain, Args_ &&...args) :
        Sync(typeid(*this).name(), drain),
        sync_(std::forward<Args_>(args)...)
    {
    }

    Sync_ *operator ->() {
        return &sync_;
    }

    task<void> Shut() noexcept override {
        orc_except({ sync_.close(); })
        co_await Link::Shut();
    }
};

template <typename Sync_>
class SyncFile :
    public Sync
{
  protected:
    Sync_ sync_;

    size_t Read_(const Mutables &buffers) override {
        return sync_.read_some(buffers);
    }

    size_t Send_(const Buffer &data) override {
        return sync_.write_some(Sequence(data));
    }

  public:
    template <typename... Args_>
    SyncFile(BufferDrain &drain, Args_ &&...args) :
        Sync(typeid(*this).name(), drain),
        sync_(std::forward<Args_>(args)...)
    {
    }

    Sync_ *operator ->() {
        return &sync_;
    }

    task<void> Shut() noexcept override {
        sync_.close();
        co_await Link::Shut();
    }
};

}

#endif//ORCHID_SYNC_HPP
