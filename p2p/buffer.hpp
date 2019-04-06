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


#ifndef ORCHID_BUFFER_HPP
#define ORCHID_BUFFER_HPP

#include <deque>
#include <functional>
#include <iostream>

#include <asio.hpp>

#include <boost/mp11/tuple.hpp>

#include "error.hpp"

namespace orc {

class Region;
class Beam;

class Buffer {
  public:
    virtual void each(const std::function<void (const Region &)> &code) const = 0;

    virtual bool null() const {
        return false;
    }

    virtual size_t size() const;
    std::string str() const;
};

std::ostream &operator <<(std::ostream &out, const Buffer &buffer);

class Region :
    public Buffer
{
  public:
    virtual const uint8_t *data() const = 0;
    size_t size() const override = 0;

    void each(const std::function<void (const Region &)> &code) const override {
        code(*this);
    }

    operator asio::const_buffer() const {
        return asio::const_buffer(data(), size());
    }
};

template <size_t Size_>
class Block :
    public Region
{
  public:
    static const size_t Size = Size_;

  private:
    std::array<uint8_t, Size_> data_;

  public:
    Block() {
    }

    Block(const void *data, size_t size) {
        _assert(size == Size_);
        memcpy(data_.data(), data, Size_);
    }

    Block(const std::string &data) :
        Block(data.data(), data.size())
    {
    }

    Block(std::initializer_list<uint8_t> list) {
        std::copy(list.begin(), list.end(), data_.begin());
    }

    Block(const Block &rhs) :
        data_(rhs.data_)
    {
    }

    virtual ~Block() {
    }

    const uint8_t *data() const override {
        return data_.data();
    }

    uint8_t *data() {
        return data_.data();
    }

    size_t size() const override {
        return Size_;
    }

    bool operator <(const Block<Size_> &rhs) const {
        return data_ < rhs.data_;
    }
};

class Beam :
    public Region
{
  private:
    size_t size_;
    uint8_t *data_;

    uint8_t &count() {
        return *data_;
    }

  public:
    Beam(size_t size) :
        size_(size),
        data_(new uint8_t[size_ + 1])
    {
        data_[0] = 1;
    }

    Beam(const void *data, size_t size) :
        Beam(size)
    {
        memcpy(data_ + 1, data, size_);
    }

    Beam(const std::string &data) :
        Beam(data.data(), data.size())
    {
    }

    Beam(const Buffer &buffer);

    Beam(const Beam &rhs) :
        size_(rhs.size_),
        data_(rhs.data_)
    {
        ++count();
    }

    virtual ~Beam() {
        if (--count() == 0)
            delete [] data_;
    }

    const uint8_t *data() const override {
        return data_ + 1;
    }

    uint8_t *data() {
        return data_ + 1;
    }

    size_t size() const override {
        return size_;
    }
};

inline bool operator ==(const Beam &lhs, const Beam &rhs) {
    auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

class Nothing :
    public Region
{
  public:
    const uint8_t *data() const override {
        return NULL;
    }

    size_t size() const override {
        return 0;
    }
};

class Null :
    public Nothing
{
  public:
    bool null() const override {
        return true;
    }
};

template <typename... Buffer_>
class Knot :
    public Buffer
{
  private:
    std::tuple<Buffer_...> buffers_;

  public:
    Knot(const Buffer_ &...buffers) :
        buffers_(buffers...)
    {
    }

    /*Knot(Buffer_ &&...buffers) :
        buffers_(std::forward<Buffer_>(buffers)...)
    {
    }*/

    void each(const std::function<void (const Region &)> &code) const override {
        boost::mp11::tuple_for_each(buffers_, [&](const auto &buffer) {
            buffer.each(code);
        });
    }
};

template <typename Type_>
struct Decay_ {
    typedef Type_ type;
};

template <typename Type_>
struct Decay_<std::reference_wrapper<Type_>> {
    typedef Type_ &type;
};

template <typename Type_>
struct Decay {
    typedef typename Decay_<typename std::decay<Type_>::type>::type type;
};

template <typename... Buffer_>
auto Cat(Buffer_ &&...buffers) {
    return Knot<typename Decay<Buffer_>::type...>(std::forward<Buffer_>(buffers)...);
}

template <typename... Buffer_>
auto Tie(Buffer_ &&...buffers) {
    return Knot<Buffer_...>(std::forward<Buffer_>(buffers)...);
}

class VectorBuffer :
    public Buffer
{
  private:
    std::vector<const Buffer *> buffers_;

  public:
    void each(const std::function<void (const Region &)> &code) const override {
        for (const auto *buffer : buffers_)
            buffer->each(code);
    }
};

class Sequence :
    public Buffer
{
  private:
    size_t count_;
    std::unique_ptr<const Region *[]> regions_;

    class Iterator {
      private:
        const Region **region_;

      public:
        Iterator(const Region **region) :
            region_(region)
        {
        }

        const Region &operator *() const {
            return **region_;
        }

        Iterator &operator ++() {
            ++region_;
            return *this;
        }

        bool operator !=(const Iterator &rhs) const {
            return region_ != rhs.region_;
        }
    };

  public:
    Sequence(const Buffer &buffer) :
        count_([&]() {
            size_t count(0);
            buffer.each([&](const Region &region) {
                ++count;
            });
            return count;
        }()),

        regions_(new const Region *[count_])
    {
        auto i(regions_.get());
        buffer.each([&](const Region &region) {
            *(i++) = &region;
        });
    }

    Iterator begin() const {
        return regions_.get();
    }

    Iterator end() const {
        return regions_.get() + count_;
    }

    void each(const std::function<void (const Region &)> &code) const override {
        for (auto i(begin()), e(end()); i != e; ++i)
            code(*i);
    }
};

class Window :
    public Buffer
{
  private:
    size_t count_;
    std::unique_ptr<const Region *[]> regions_;

    class Iterator :
        public Region
    {
        friend class Window;

      private:
        const Region **region_;
        size_t offset_;

      public:
        Iterator() :
            region_(NULL),
            offset_(0)
        {
        }

        Iterator(const Region **region, size_t offset) :
            region_(region),
            offset_(offset)
        {
        }

        const uint8_t *data() const override {
            return (*region_)->data() + offset_;
        }

        size_t size() const override {
            return (*region_)->size() - offset_;
        }
    } index_;

  public:
    Window() :
        count_(0)
    {
    }

    Window(const Buffer &buffer) :
        count_([&]() {
            size_t count(0);
            buffer.each([&](const Region &region) {
                ++count;
            });
            return count;
        }()),

        regions_(new const Region *[count_]),

        index_(regions_.get(), 0)
    {
        auto i(regions_.get());
        buffer.each([&](const Region &region) {
            *(i++) = &region;
        });
    }

    Window(Window &&rhs) = default;
    Window &operator =(Window &&rhs) = default;

    void each(const std::function<void (const Region &)> &code) const override {
        auto here(index_.region_);
        auto rest(regions_.get() + count_ - here);
        if (rest == 0)
            return;

        size_t i;
        if (index_.offset_ == 0)
            i = 0;
        else {
            i = 1;
            code(index_);
        }

        for (; i != rest; ++i)
            code(*here[i]);
    }

    template <size_t Size_>
    void Take(Block<Size_> &value) {
        auto data(value.data());

        auto &here(index_.region_);
        auto &step(index_.offset_);

        auto rest(regions_.get() + count_ - here);

        for (auto need(Size_); need != 0; step = 0, ++here, --rest) {
            _assert(rest != 0);

            auto size((*here)->size() - step);
            if (size == 0)
                continue;

            if (need < size) {
                memcpy(data, (*here)->data() + step, need);
                std::cerr << step << " " << value << std::endl;
                step += need;
                break;
            }

            memcpy(data, (*here)->data() + step, size);
            data += size;
            need -= size;
        }
    }
};

template <size_t Size_>
struct Taken {
    typedef Block<Size_> type;
};

template <>
struct Taken<0> {
    typedef Window type;
};

template <size_t Index_, size_t... Size_>
struct Taker {};

template <size_t Index_, size_t Size_, size_t... Rest_>
struct Taker<Index_, Size_, Rest_...> {
template <typename Type_>
static void Take(Window &&window, Type_ &value) {
    window.Take(std::get<Index_>(value));
    Taker<Index_ + 1, Rest_...>::Take(std::move(window), value);
} };

template <size_t Index_>
struct Taker<Index_, 0> {
template <typename Type_>
static void Take(Window &&window, Type_ &value) {
    std::get<Index_>(value) = std::move(window);
} };

template <size_t Index_>
struct Taker<Index_> {
template <typename Type_>
static void Take(Window &&window, Type_ &value) {
    _assert(window.size() == 0);
} };

template <size_t... Size_>
auto Take(const Buffer &buffer) {
    std::tuple<typename Taken<Size_>::type...> value;
    Taker<0, Size_...>::Take(buffer, value);
    return value;
}

}

#endif//ORCHID_BUFFER_HPP
