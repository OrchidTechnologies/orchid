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
#include "spawn.hpp"

namespace orc {

struct Mutables {
  private:
    const asio::mutable_buffer *const data_;
    const size_t size_;

  public:
    Mutables(const asio::mutable_buffer &data) :
        data_(&data),
        size_(1)
    {
    }

    auto begin() const {
        return data_;
    }

    auto end() const {
        return data_ + size_;
    }
};

class Reader {
  public:
    virtual ~Reader() = default;
    virtual task<size_t> Read(const Mutables &buffers) = 0;
};

class Stream :
    public Reader
{
  public:
    ~Stream() override = default;
    virtual void Shut() noexcept = 0;
    virtual task<void> Send(const Buffer &data) = 0;
};


// XXX: the Stream interface doesn't support reading truncated messages correctly
// we should remove Inverted and provide a better framework for Duplex and UDP :/

class Inverted :
    public Pump<Buffer>
{
  private:
    U<Stream> stream_;

  public:
    Inverted(BufferDrain &drain, U<Stream> stream) :
        Pump<Buffer>(drain),
        stream_(std::move(stream))
    {
        type_ = typeid(*this).name();
    }

    void Open() noexcept {
        Spawn([this]() noexcept -> task<void> {
            Beam beam(2048);
            for (;;) {
                size_t writ;
                try {
                    writ = co_await stream_->Read(asio::buffer(beam.data(), beam.size()));
                } catch (const Error &error) {
                    const auto &what(error.what_);
                    orc_insist(!what.empty());
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
        }, __FUNCTION__);
    }

    task<void> Shut() noexcept override {
        stream_->Shut();
        co_await Valve::Shut();
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await stream_->Send(data);
    }
};

}

#endif//ORCHID_READER_HPP
