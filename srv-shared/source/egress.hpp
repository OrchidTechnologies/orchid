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
#include "locked.hpp"
#include "socket.hpp"

namespace orc {

class Translator;

class Egress :
    public Valve,
    public Pipe<Buffer>,
    public BufferDrain
{
  private:
    const uint32_t local_;
    const uint16_t ephemeral_base_ = 4096;

    typedef std::list<const Three> LRU_;

    struct Translation_ {
        const Socket socket_;
        Translator &translator_;
        LRU_::iterator lru_iter_;
    };

    struct Locked_ {
        std::map<Three, Translation_> translations_;
        LRU_ lru_;
    }; Locked<Locked_> locked_;

    std::optional<std::pair<const Socket, Translator &>> Find(const Three &target);

  protected:
    virtual Pump<Buffer> *Inner() = 0;

    void Land(const Buffer &data) override;
    void Stop(const std::string &error) noexcept override;

  public:
    Egress(uint32_t local) :
        local_(local)
    {
    }

    ~Egress() override {
        orc_insist(false);
    }

    task<void> Shut() noexcept override {
        co_await Inner()->Shut();
        co_await Valve::Shut();
    }

    task<void> Send(const Buffer &data) override {
        co_await Inner()->Send(data);
    }

    Socket Translate(Translator &translator, const Three &three);
};


class Translator:
    public Link<Buffer>
{
  private:
    S<Egress> egress_;

    typedef std::map<Three, Socket> Translations_;

    struct Locked_ {
        Translations_ translations_;
    }; Locked<Locked_> locked_;

    Socket Translate(const Three &source) {
        const auto locked(locked_());
        const auto translation(locked->translations_.find(source));
        if (translation != locked->translations_.end())
            return translation->second;
        const auto socket(egress_->Translate(*this, source));
        orc_insist(locked->translations_.emplace(source, socket).second);
        return socket;
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
        const auto locked(locked_());
        auto &translations(locked->translations_);
        orc_insist(translations.find(source) != translations.end());
        translations.erase(source);
    }
};

}

#endif//ORCHID_EGRESS_HPP
