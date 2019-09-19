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


#ifndef ORCHID_LINK_HPP
#define ORCHID_LINK_HPP

#include <functional>
#include <map>
#include <set>

#include <cppcoro/async_manual_reset_event.hpp>

#include "buffer.hpp"
#include "crypto.hpp"
#include "error.hpp"
#include "shared.hpp"
#include "task.hpp"

namespace orc {

typedef Number<uint32_t> Tag;
static const size_t TagSize = sizeof(uint32_t);
inline Tag NewTag() {
    return Random<TagSize>();
}

class Pipe {
  public:
    static uint64_t Unique_;
    const uint64_t unique_ = ++Unique_;

    static void Insert(Pipe *pipe);
    static void Remove(Pipe *pipe);

  public:
    Pipe() {
        Insert(this);
    }

    virtual ~Pipe() {
        Remove(this);
    }

    virtual task<void> Send(const Buffer &data) = 0;
};

template <typename Type_>
class Drain {
  public:
    virtual void Land(Type_ data) = 0;
    virtual void Stop(const std::string &error = std::string()) = 0;
};

using BufferDrain = Drain<const Buffer &>;

class Valve :
    public Pipe
{
  private:
    cppcoro::async_manual_reset_event shut_;

  protected:
    void Stop() {
        orc_assert(!shut_.is_set());
        shut_.set();
    }

  public:
    ~Valve() override {
        if (Verbose)
            Log() << "##### " << unique_ << std::endl;
        orc_insist(shut_.is_set());
    }

    virtual task<void> Shut() {
        co_await shut_;
        co_await Schedule();
    }
};

template <typename Drain_>
class Pump :
    public Valve
{
  private:
    Drain_ *const drain_;

  protected:
    Drain_ *Outer() {
        return drain_;
    }

  public:
    Pump(Drain_ *drain) :
        drain_(drain)
    {
    }
};

class Link :
    public Pump<BufferDrain>,
    public BufferDrain
{
  protected:
    void Land(const Buffer &data) override {
        return Outer()->Land(data);
    }

    void Stop(const std::string &error = std::string()) override {
        Pump<BufferDrain>::Stop();
        return Outer()->Stop(error);
    }

  public:
    Link(BufferDrain *drain) :
        Pump<BufferDrain>(drain)
    {
    }
};

template <typename Inner_ = Link, typename Drain_ = BufferDrain>
class Sunk {
  protected:
    U<Inner_> inner_;

  public:
    virtual Drain_ *Gave() = 0;

    template <typename Type_, typename... Args_>
    Type_ *Wire(Args_ &&...args) {
        auto inner(std::make_unique<Type_>(Gave(), std::forward<Args_>(args)...));
        auto backup(inner.get());
        inner_ = std::move(inner);
        return backup;
    }
};

template <typename Base_, typename Inner_ = Link, typename Drain_ = BufferDrain>
class Sink final :
    public Base_,
    public Sunk<Inner_, Drain_>
{
  protected:
    Inner_ *Inner() override {
        auto inner(this->inner_.get());
        orc_insist(inner != nullptr);
        return inner;
    }

    Drain_ *Gave() override {
        return this;
    }

  public:
    using Base_::Base_;
};

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

#endif//ORCHID_LINK_HPP
