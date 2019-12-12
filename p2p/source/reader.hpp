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


#ifndef ORCHID_READER_HPP
#define ORCHID_READER_HPP

#include "buffer.hpp"
#include "link.hpp"
#include "task.hpp"

namespace orc {

class Reader {
  public:
    virtual ~Reader() = default;
    virtual task<size_t> Read(Beam &beam) = 0;
};

class Stream :
    public Reader,
    public Pipe<Buffer>
{
  public:
    ~Stream() override = default;
    virtual task<void> Shut() = 0;
};

class Inverted final :
    public Pump<Buffer>
{
  private:
    U<Stream> stream_;

  public:
    Inverted(BufferDrain *drain, U<Stream> stream) :
        Pump<Buffer>(drain),
        stream_(std::move(stream))
    {
    }

    void Open() {
        Spawn([this]() -> task<void> {
            Beam beam(2048);
            for (;;) {
                size_t writ;
                try {
                    writ = co_await stream_->Read(beam);
                } catch (const Error &error) {
                    orc_insist(!error.text.empty());
                    Pump::Stop(error.text);
                    break;
                }

                if (writ == 0) {
                    Pump::Stop();
                    break;
                }

                const auto subset(beam.subset(0, writ));
                Pump::Land(subset);
            }
        });
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await stream_->Send(data);
    }

    task<void> Shut() override {
        co_await stream_->Shut();
        co_await Valve::Shut();
    }
};

}

#endif//ORCHID_READER_HPP
