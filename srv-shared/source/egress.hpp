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


#ifndef ORCHID_EGRESS_HPP
#define ORCHID_EGRESS_HPP

#include <map>

#include "link.hpp"
#include "socket.hpp"

namespace orc {

class Translator;

class Egress :
    public Valve,
    public Pipe<Buffer>,
    public BufferDrain
{
  private:
    uint32_t local_;
    uint16_t ephemeral_base_ = 4096;

    typedef std::list<Three> LRU_;

    struct Translation_ {
        Socket socket_;
        Translator *translator_;
        LRU_::iterator lru_iter_;
    };

    typedef std::map<Three, Translation_> Translations_;
    std::mutex mutex_;
    Translations_ translations_;
    LRU_ lru_;

    Translations_::iterator Find(const Three &target);

  protected:
    virtual Pump *Inner() = 0;

    void Land(const Buffer &data) override;

    void Stop(const std::string &error) override;

  public:
    Egress(uint32_t local) :
        local_(local)
    {
    }

    ~Egress() override {
        orc_insist(false);
    }

    task<void> Shut() override {
        co_await Inner()->Shut();
        co_await Valve::Shut();
    }

    task<void> Send(const Buffer &data) override {
        co_await Inner()->Send(data);
    }

    const Socket &Translate(Translator *translator, const Three &three);
};


class Translator:
    public Link
{
  private:
    S<Egress> egress_;
    std::mutex mutex_;

    typedef std::map<Three, Socket> Translations_;
    Translations_ translations_;

    Translations_::iterator Translate(const Three &source) {
        auto socket(egress_->Translate(this, source));
        auto translation(translations_.emplace(source, socket));
        return translation.first;
    }

  public:
    Translator(BufferDrain *drain, S<Egress> egress) :
        Link(drain),
        egress_(std::move(egress))
    {
    }

    task<void> Send(const Buffer &data) override;
    using Link::Stop;
    using Link::Land;

    void Remove(const Three &source) {
        std::unique_lock<std::mutex> lock(mutex_);
        orc_insist(translations_.find(source) != translations_.end());
        translations_.erase(source);
    }
};

}

#endif//ORCHID_EGRESS_HPP
