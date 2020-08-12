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

// XXX: there is a serious denial of service attack in this system

#include <map>

#include "event.hpp"
#include "link.hpp"
#include "locked.hpp"
#include "socket.hpp"

namespace orc {

class Egress :
    public Valve,
    public BufferDrain,
    public Sunken<Pump<Buffer>>
{
  private:
    const uint32_t local_;
    const uint16_t ephemeral_ = 4096;

    class Translator;

    struct Neutral {
        std::atomic<unsigned> usage_ = 0;
        std::atomic<bool> shutting_ = false;
        Event shut_;
    };

    typedef std::map<Translator *, Neutral *> Translators;
    typedef std::list<const Three> Recents;

    struct Translation {
        const Socket translated_;
        Translator &translator_;
        Neutral *neutral_;

        Translation(Socket translated, Translator &translator, Neutral *neutral) :
            translated_(translated),
            translator_(translator),
            neutral_(neutral)
        {
        }

        Translation(const Translation &rhs) = delete;

        Translation(Translation &&rhs) noexcept :
            translated_(rhs.translated_),
            translator_(rhs.translator_),
            neutral_(rhs.neutral_)
        {
            rhs.neutral_ = nullptr;
        }

        ~Translation() {
            if (neutral_ != nullptr && --neutral_->usage_ == 0 && neutral_->shutting_)
                neutral_->shut_();
        }
    };

    struct External {
        const Socket translated_;
        const Translators::iterator indirect_;
        const Recents::iterator recent_;
    };

    typedef std::map<Three, External> Externals;

    struct Internal {
        const Socket translated_;
        const Externals::iterator external_;
    };

    typedef std::map<Three, Internal> Internals;

    struct Locked_ {
        Externals externals_;
        Translators translators_;
        Recents recents_;
    }; Locked<Locked_> locked_;

    class Translator:
        public Link<Buffer>
    {
        friend class Egress;

      private:
        const S<Egress> egress_;
        Neutral neutral_;
        const Translators::iterator indirect_;

        struct Locked_ {
            Internals internals_;
        }; Locked<Locked_> locked_;

        Socket Translate(const Three &source);

        template <typename Code_>
        auto Access(const Code_ &code) -> decltype(code(std::declval<Internals &>())) {
            const auto locked(locked_());
            return code(locked->internals_);
        }

      public:
        Translator(BufferDrain &drain, S<Egress> egress) :
            Link(drain),
            egress_(std::move(egress)),
            indirect_(egress_->Open(this, &neutral_))
        {
        }

        task<void> Shut() noexcept override {
            co_await egress_->Shut(indirect_);
            co_await Link::Shut();
        }

        task<void> Send(const Buffer &data) override;
    };

    Socket Translate(Translators::iterator, const Three &source);
    std::optional<Translation> Find(const Three &destination);

    Translators::iterator Open(Translator *translator, Neutral *neutral);
    task<void> Shut(Translators::iterator indirect) noexcept;

    task<void> Send(const Buffer &data) {
        co_await Inner().Send(data);
    }

  protected:
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

    static void Wire(S<Egress> self, BufferSunk &sunk) {
        sunk.Wire<Translator>(std::move(self));
    }

    task<void> Shut() noexcept override {
        co_await Sunken::Shut();
        co_await Valve::Shut();
        orc_insist(false);
    }
};

}

#endif//ORCHID_EGRESS_HPP
