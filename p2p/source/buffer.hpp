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

#include <boost/endian/conversion.hpp>
#include <boost/mp11/tuple.hpp>
#include <boost/multiprecision/cpp_int.hpp>

#include "error.hpp"
#include "trace.hpp"

namespace orc {

using boost::multiprecision::uint256_t;

class Region;
class Beam;

class Buffer {
  public:
    virtual bool each(const std::function<bool (const Region &)> &code) const = 0;

    virtual size_t size() const;

    virtual bool empty() const {
        return size() == 0;
    }

    size_t copy(uint8_t *data, size_t size) const;

    size_t copy(char *data, size_t size) const {
        return copy(reinterpret_cast<uint8_t *>(data), size);
    }

    std::string str() const;
    std::string hex() const;
};

std::ostream &operator <<(std::ostream &out, const Buffer &buffer);

template <typename Type_, bool Arithmetic = std::is_arithmetic<Type_>::value>
struct Cast;

template <typename Type_>
struct Cast<Type_, true> {
    static Type_ Load(const uint8_t *data, size_t size) {
        orc_assert(size == sizeof(Type_));
        return boost::endian::big_to_native(*reinterpret_cast<const Type_ *>(data));
    }
};

template <>
struct Cast<uint256_t, false> {
    static uint256_t Load(const uint8_t *data, size_t size) {
        orc_assert(size == 32);
        uint256_t value;
        boost::multiprecision::import_bits(value, std::reverse_iterator(data + size), std::reverse_iterator(data), 8, false);
        return value;
    }
};

class Region :
    public Buffer
{
  public:
    virtual const uint8_t *data() const = 0;
    size_t size() const override = 0;

    bool each(const std::function<bool (const Region &)> &code) const override {
        return code(*this);
    }

    operator asio::const_buffer() const {
        return asio::const_buffer(data(), size());
    }

    template <typename Type_>
    Type_ num() const {
        return Cast<Type_>::Load(data(), size());
    }
};

class Subset final :
    public Region
{
  private:
    const uint8_t *const data_;
    const size_t size_;

  public:
    Subset(const uint8_t *data, size_t size) :
        data_(data),
        size_(size)
    {
    }

    Subset(const char *data, size_t size) :
        data_(reinterpret_cast<const uint8_t *>(data)),
        size_(size)
    {
    }

    Subset(const std::string &data) :
        Subset(data.data(), data.size())
    {
    }

    const uint8_t *data() const override {
        return data_;
    }

    size_t size() const override {
        return size_;
    }
};

template <typename Data_>
class Strung final :
    public Region
{
  private:
    const Data_ data_;

  public:
    Strung(Data_ data) :
        data_(std::move(data))
    {
    }

    const uint8_t *data() const override {
        return reinterpret_cast<const uint8_t *>(data_.data());
    }

    size_t size() const override {
        return data_.size();
    }
};

template <size_t Size_>
class Data :
    public Region
{
  protected:
    std::array<uint8_t, Size_> data_;

  public:
    Data() {
    }

    Data(const std::array<uint8_t, Size_> &data) :
        data_(data)
    {
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

    bool operator <(const Data<Size_> &rhs) const {
        return data_ < rhs.data_;
    }
};

template <size_t Size_>
class Brick final :
    public Data<Size_>
{
  public:
    static const size_t Size = Size_;

  public:
    Brick() {
    }

    Brick(const void *data, size_t size) {
        orc_assert(size == Size_);
        memcpy(this->data_.data(), data, Size_);
    }

    Brick(const std::string &data) :
        Brick(data.data(), data.size())
    {
    }

    explicit Brick(std::initializer_list<uint8_t> list) {
        std::copy(list.begin(), list.end(), this->data_.begin());
    }

    Brick(const Brick &rhs) :
        Data<Size_>(rhs.data_)
    {
    }

    uint8_t &operator [](size_t index) {
        return this->data_[index];
    }

    template <size_t Clip_>
    typename std::enable_if<Clip_ <= Size_, Brick<Clip_>>::type Clip() {
        Brick<Clip_> value;
        for (size_t i(0); i != Clip_; ++i)
            value[i] = this->data_[i];
        return value;
    }
};

template <typename Type_, bool Arithmetic_ = std::is_arithmetic<Type_>::value>
class Number;

template <typename Type_>
class Number<Type_, true> final :
    public Region
{
  private:
    const Type_ value_;

  public:
    Number(Type_ value) :
        value_(boost::endian::native_to_big(value))
    {
    }

    operator Type_() const {
        return value_;
    }

    const uint8_t *data() const override {
        return reinterpret_cast<const uint8_t *>(&value_);
    }

    size_t size() const override {
        return sizeof(Type_);
    }
};

template <unsigned Bits_, boost::multiprecision::cpp_integer_type Sign_, boost::multiprecision::cpp_int_check_type Check_>
class Number<boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, Sign_, Check_, void>>, false> final :
    public Data<(Bits_ >> 3)>
{
  public:
    Number(boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, Sign_, Check_, void>> value) {
        boost::multiprecision::export_bits(value, this->data_.rbegin(), 8, false);
    }

    Number(const std::string &value) :
        Number(boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, Sign_, Check_, void>>(value))
    {
    }
};

class Beam :
    public Region
{
  private:
    size_t size_;
    uint8_t *data_;

    void destroy() {
        delete [] data_;
    }

  public:
    Beam() :
        size_(0),
        data_(NULL)
    {
    }

    Beam(size_t size) :
        size_(size),
        data_(new uint8_t[size_])
    {
    }

    Beam(const void *data, size_t size) :
        Beam(size)
    {
        memcpy(data_, data, size_);
    }

    Beam(const std::string &data) :
        Beam(data.data(), data.size())
    {
    }

    Beam(const Buffer &buffer);

    Beam(Beam &&rhs) noexcept :
        size_(rhs.size_),
        data_(rhs.data_)
    {
        rhs.size_ = 0;
        rhs.data_ = nullptr;
    }

    Beam(const Beam &rhs) = delete;

    virtual ~Beam() {
        destroy();
    }

    Beam &operator =(Beam &&rhs) {
        destroy();
        size_ = rhs.size_;
        data_ = rhs.data_;
        rhs.size_ = 0;
        rhs.data_ = nullptr;
        return *this;
    }

    const uint8_t *data() const override {
        return data_;
    }

    uint8_t *data() {
        return data_;
    }

    size_t size() const override {
        return size_;
    }

    const uint8_t &operator [](size_t index) const {
        return data_[index];
    }

    uint8_t &operator [](size_t index) {
        return data_[index];
    }
};

Beam Bless(const std::string &data);

template <typename Data_>
inline bool operator ==(const Beam &lhs, const std::string &rhs) {
    auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

template <typename Data_>
inline bool operator ==(const Beam &lhs, const Strung<Data_> &rhs) {
    auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

template <size_t Size_>
inline bool operator ==(const Beam &lhs, const Brick<Size_> &rhs) {
    auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

inline bool operator ==(const Beam &lhs, const Beam &rhs) {
    auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

bool operator ==(const Beam &lhs, const Buffer &rhs);

template <typename Buffer_>
inline bool operator !=(const Beam &lhs, const Buffer_ &rhs) {
    return !(lhs == rhs);
}

class Nothing final :
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

template <typename... Buffer_>
class Knot final :
    public Buffer
{
  private:
    const std::tuple<const Buffer_ &...> buffers_;

  public:
    Knot(const Buffer_ &...buffers) :
        buffers_(buffers...)
    {
    }

    bool each(const std::function<bool (const Region &)> &code) const override {
        bool value(true);
        boost::mp11::tuple_for_each(buffers_, [&](const auto &buffer) {
            value &= buffer.each(code);
        });
        return value;
    }
};

template <typename... Buffer_>
auto Tie(Buffer_ &&...buffers) {
    return Knot<Buffer_...>(std::forward<Buffer_>(buffers)...);
}

class Sequence final :
    public Buffer
{
  private:
    size_t count_;
    std::unique_ptr<const Region *[]> regions_;

    class Iterator {
      private:
        const Region *const *region_;

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
                return true;
            });
            return count;
        }()),

        regions_(new const Region *[count_])
    {
        auto i(regions_.get());
        buffer.each([&](const Region &region) {
            *(i++) = &region;
            return true;
        });
    }

    Sequence(Sequence &&sequence) :
        count_(sequence.count_),
        regions_(std::move(sequence.regions_))
    {
    }

    Sequence(const Sequence &sequence) :
        count_(sequence.count_),
        regions_(new const Region *[count_])
    {
        auto old(sequence.regions_.get());
        std::copy(old, old + count_, regions_.get());
    }

    Iterator begin() const {
        return regions_.get();
    }

    Iterator end() const {
        return regions_.get() + count_;
    }

    bool each(const std::function<bool (const Region &)> &code) const override {
        for (auto i(begin()), e(end()); i != e; ++i)
            if (!code(*i))
                return false;
        return true;
    }
};

class Window final :
    public Buffer
{
  private:
    size_t count_;
    std::unique_ptr<const Region *[]> regions_;

    class Iterator final :
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
                return true;
            });
            return count;
        }()),

        regions_(new const Region *[count_]),

        index_(regions_.get(), 0)
    {
        auto i(regions_.get());
        buffer.each([&](const Region &region) {
            *(i++) = &region;
            return true;
        });
    }

    Window(Window &&rhs) = default;
    Window &operator =(Window &&rhs) = default;

    bool each(const std::function<bool (const Region &)> &code) const override {
        auto here(index_.region_);
        auto rest(regions_.get() + count_ - here);
        if (rest == 0)
            return true;

        size_t i;
        if (index_.offset_ == 0)
            i = 0;
        else {
            i = 1;
            if (!code(index_))
                return false;
        }

        for (; i != rest; ++i)
            if (!code(*here[i]))
                return false;

        return true;
    }

    void Stop() {
        orc_assert(empty());
    }

    void Take(uint8_t *data, size_t size) {
        Beam beam(size);

        auto &here(index_.region_);
        auto &step(index_.offset_);

        auto rest(regions_.get() + count_ - here);

        for (auto need(size); need != 0; step = 0, ++here, --rest) {
            orc_assert(rest != 0);

            auto size((*here)->size() - step);
            if (size == 0)
                continue;

            if (need < size) {
                memcpy(data, (*here)->data() + step, need);
                step += need;
                break;
            }

            memcpy(data, (*here)->data() + step, size);
            data += size;
            need -= size;
        }
    }

    void Take(std::string &data) {
        Take(reinterpret_cast<uint8_t *>(data.data()), data.size());
    }

    uint8_t Take() {
        uint8_t value;
        Take(&value, 1);
        return value;
    }

    template <size_t Size_>
    void Take(Brick<Size_> &value) {
        Take(value.data(), value.size());
    }

    Beam Take(size_t size) {
        Beam beam(size);
        Take(beam.data(), beam.size());
        return beam;
    }

    void Skip(size_t size) {
        auto data(Take(size));
        for (size_t i(0); i != size; ++i)
            orc_assert(data[i] == 0);
    }
};

template <size_t Size_>
struct Taken {
    typedef Brick<Size_> type;
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
    window.Stop();
} };

template <size_t... Size_>
auto Take(const Buffer &buffer) {
    std::tuple<typename Taken<Size_>::type...> value;
    Taker<0, Size_...>::Take(buffer, value);
    return value;
}

}

#endif//ORCHID_BUFFER_HPP
