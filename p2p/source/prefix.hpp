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


#ifndef ORCHID_PREFIX_HPP
#define ORCHID_PREFIX_HPP

#include <map>

#include "link.hpp"
#include "tag.hpp"

namespace orc {

template <typename Link_>
class Prefixed :
    public Pipe,
    public BufferDrain
{
    template <typename Prefixed_>
    friend class Prefix;

  private:
    std::map<Tag, BufferDrain *> prefixes_;

  protected:
    void Land(const Buffer &data) override {
        auto [tag, rest] = Take<Tag, Window>(data);
        auto prefix(prefixes_.find(tag));
        orc_assert(prefix != prefixes_.end());
        prefix->second->Land(rest);
    }

    void Stop(const std::string &error) override {
        for (const auto &[tag, drain] : prefixes_)
            drain->Stop(error);
    }

  public:
    ~Prefixed() override {
        orc_insist(prefixes_.empty());
    }
};

template <typename Prefixed_>
class Prefix final :
    public Link
{
  public:
    const S<Prefixed_> prefixed_;
    const Tag tag_;

  public:
    Prefix(BufferDrain *drain, const S<Prefixed_> prefixed) :
        Link(drain),
        prefixed_(prefixed),
        tag_([this]() {
            BufferDrain *drain(this);
            for (;;) {
                auto tag(NewTag());
                if (prefixed_->prefixes_.emplace(tag, drain).second)
                    return tag;
            }
        }())
    {
    }

    ~Prefix() override {
        prefixed_->prefixes_.erase(tag_);
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await prefixed_->Send(Tie(tag_, data));
    }

    void Stop(const std::string &error = std::string()) override {
        Link::Stop(error);
    }

    const S<Prefixed_> &operator ->() {
        return prefixed_;
    }
};

}

#endif//ORCHID_PREFIX_HPP
