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


#ifndef ORCHID_SYNC_HPP
#define ORCHID_SYNC_HPP

#include "baton.hpp"
#include "link.hpp"
#include "reader.hpp"

namespace orc {

template <typename Sync_, typename Traits_>
class Sync :
    public Pump<Buffer>
{
  private:
    Sync_ sync_;

  public:
    template <typename... Args_>
    Sync(BufferDrain &drain, Args_ &&...args) :
        Pump(typeid(*this).name(), drain),
        sync_(std::forward<Args_>(args)...)
    {
    }

    Sync_ *operator ->() {
        return &sync_;
    }

    size_t Read(const Mutables &buffers) {
        size_t writ;
        try {
            writ = Traits_::Read(sync_, buffers);
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
                    writ = Read(asio::mutable_buffer(beam.data(), beam.size()));
                } catch (const std::exception &error) {
                    const auto what(error.what());
                    orc_insist(what != nullptr);
                    orc_insist(*what != '\0');
                    Pump::Stop(what);
                    break;
                }

                if (writ == 0) {
                    Pump::Stop();
                    break;
                }

                const auto subset(beam.subset(0, writ));
                Pump::Land(subset);
            }
        }).detach();
    }

    task<void> Send(const Buffer &data) override {
        size_t writ;
        try {
            writ = Traits_::Send(sync_, data);
        } catch (const asio::system_error &error) {
            orc_adapt(error);
        }
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");

        co_return;
    }
};

struct SyncConnection {
    template <typename Sync_>
    static size_t Read(Sync_ &sync, const Mutables &buffers) {
        return sync.receive(buffers);
    }

    template <typename Sync_>
    static size_t Send(Sync_ &sync, const Buffer &data) {
        return sync.send(Sequence(data));
    }

    template <typename Sync_>
    static void Shut(Sync_ &sync) noexcept {
        orc_except({ sync.close(); })
    }
};

struct SyncFile {
    template <typename Sync_>
    static size_t Read(Sync_ &sync, const Mutables &buffers) {
        return sync.read_some(buffers);
    }

    template <typename Sync_>
    static size_t Send(Sync_ &sync, const Buffer &data) {
        return sync.write_some(Sequence(data));
    }

    template <typename Sync_>
    static void Shut(Sync_ &sync) noexcept {
        sync.close();
    }
};

}

#endif//ORCHID_SYNC_HPP
