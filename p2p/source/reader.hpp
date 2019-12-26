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

#include <queue>

#include <cppcoro/async_auto_reset_event.hpp>

#include "buffer.hpp"
#include "link.hpp"
#include "locked.hpp"
#include "task.hpp"

namespace orc {

class Reader {
  public:
    virtual ~Reader() = default;
    virtual task<size_t> Read(Beam &beam) = 0;
};

class Stream :
    public Valve,
    public Pipe<Buffer>,
    public Reader
{
  public:
    explicit Stream(bool set) :
        Valve(set)
    {
    }

    ~Stream() override = default;
};

class Reverted :
    public Stream,
    public BufferDrain
{
  private:
    struct Locked_ {
        std::queue<Beam> data_;
        size_t offset_ = 0;
    }; Locked<Locked_> locked_;

    cppcoro::async_auto_reset_event ready_;

  protected:
    virtual Pump<Buffer> *Inner() = 0;

    void Land(const Buffer &data) override {
        locked_()->data_.emplace(data);
        ready_.set();
    }

    void Stop(const std::string &error) noexcept override {
        locked_()->data_.emplace(Beam());
        ready_.set();
        Stream::Stop();
    }

  public:
    Reverted() :
        Stream(false)
    {
    }

    task<size_t> Read(Beam &data) override {
        for (;; co_await ready_, co_await Schedule()) {
            const auto locked(locked_());
            if (locked->data_.empty())
                continue;
            const auto &next(locked->data_.front());

            // XXX: handle errors
            const auto base(next.data());
            const auto rest(next.size() - locked->offset_);
            if (rest == 0)
                co_return 0;

            const auto writ(std::min(data.size(), rest));
            Copy(data.data(), base + locked->offset_, writ);

            if (rest != writ)
                locked->offset_ += writ;
            else {
                locked->data_.pop();
                locked->offset_ = 0;
            }

            co_return writ;
        }
    }

    task<void> Shut() noexcept override {
        co_await Inner()->Shut();
        co_await Stream::Shut();
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner()->Send(data);
    }
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
        type_ = typeid(*this).name();
    }

    void Open() noexcept {
        Spawn([this]() noexcept -> task<void> {
            Beam beam(2048);
            for (;;) {
                size_t writ;
                try {
                    writ = co_await stream_->Read(beam);
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
        });
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await stream_->Send(data);
    }

    task<void> Shut() noexcept override {
        co_await stream_->Shut();
        co_await Valve::Shut();
    }
};

}

#endif//ORCHID_READER_HPP
