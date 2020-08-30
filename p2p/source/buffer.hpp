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

#include <atomic>
#include <deque>
#include <functional>
#include <iostream>
#include <list>
#include <string>

#include <cppcoro/generator.hpp>

#include <asio.hpp>

#include <boost/endian/conversion.hpp>
#include <boost/mp11/tuple.hpp>

#include <intx/intx.hpp>

#include "error.hpp"
#include "integer.hpp"

namespace orc {

extern std::atomic<uint64_t> copied_;

inline void Copy(void *dst, const void *src, size_t len) {
    memcpy(dst, src, len);
    copied_ += len;
}

template <typename Type_ = size_t>
class Range {
  protected:
    Type_ data_;
    size_t size_;

  public:
    Range() = default;

    Range(Type_ data, size_t size) :
        data_(data),
        size_(size)
    {
    }

    Type_ data() const {
        return data_;
    }

    size_t size() const {
        return size_;
    }
};

class Region;
class Beam;

class Buffer {
  public:
    virtual bool each(const std::function<bool (const uint8_t *, size_t)> &code) const = 0;

    virtual size_t size() const;
    virtual bool have(size_t value) const;
    virtual bool zero() const;
    virtual bool done() const;

    void copy(uint8_t *data, size_t size) const;

    void copy(char *data, size_t size) const {
        copy(reinterpret_cast<uint8_t *>(data), size);
    }

    std::string str() const;
    std::string hex() const;
};

std::ostream &operator <<(std::ostream &out, const Buffer &buffer);

template <typename Type_, typename Enable_ = void>
struct Cast;

template <typename Type_>
struct Cast<Type_, typename std::enable_if<std::is_arithmetic<Type_>::value>::type> {
    static auto Load(const uint8_t *data, size_t size) {
        orc_assert(size == sizeof(Type_));
        return boost::endian::big_to_native(*reinterpret_cast<const Type_ *>(data));
    }
};

template <unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_>
struct Cast<boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>>, typename std::enable_if<Bits_ % 8 == 0>::type> {
    static auto Load(const uint8_t *data, size_t size) {
        orc_assert(size == Bits_ / 8);
        boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>> value;
        boost::multiprecision::import_bits(value, std::reverse_iterator(data + size), std::reverse_iterator(data), 8, false);
        return value;
    }
};

template <unsigned Bits_>
struct Cast<intx::uint<Bits_>, typename std::enable_if<Bits_ % 8 == 0>::type> {
    static auto Load(const uint8_t *data, size_t size) {
        orc_assert(size == Bits_ / 8);
        return intx::be::load<intx::uint<Bits_>>(*reinterpret_cast<const uint8_t (*)[Bits_ / 8]>(data));
    }
};

template <typename Type_ = uint8_t>
class Span :
    public Range<Type_ *>
{
  public:
    Span() = default;

    Span(Type_ *data, size_t size) :
        Range<Type_ *>(data, size)
    {
    }

    Span(const Span &span) :
        Span(span.data(), span.size())
    {
    }

    template <size_t Size_>
    Span(Type_ (&data)[Size_]) :
        Span(data, Size_)
    {
    }

    Span(std::initializer_list<Type_> list) :
        Span(list.begin(), list.size())
    {
    }

    Span(const std::basic_string<std::remove_const_t<Type_>> &data) :
        Span(data.data(), data.size())
    {
    }

    template <typename Cast_>
    Cast_ &cast(size_t offset = 0) {
        static_assert(sizeof(Type_) == 1);
        orc_assert_(this->size() >= offset + sizeof(Cast_), "orc_assert(" << this->size() << " {size()} >= " << offset << " {offset} + " << sizeof(Cast_) << " {sizeof(" << typeid(Cast_).name() << ")})");
        return *reinterpret_cast<Cast_ *>(this->data() + offset);
    }

    template <typename Cast_>
    Cast_ &take() {
        static_assert(sizeof(Type_) == 1);
        orc_assert(this->size_ >= sizeof(Type_));
        const auto value(reinterpret_cast<Cast_ *>(this->data_));
        this->data_ += sizeof(Type_);
        this->size_ -= sizeof(Type_);
        return *value;
    }

    operator Span<const Type_>() const {
        return {this->data_, this->size_};
    }

    operator std::basic_string_view<std::remove_const_t<Type_>>() const {
        return {this->data_, this->size_};
    }

    explicit operator std::basic_string<std::remove_const_t<Type_>>() const {
        return {this->data_, this->size_};
    }

    Span operator +(size_t offset) const {
        orc_assert(this->size_ >= offset);
        return Span(this->data_ + offset, this->size_ - offset);
    }

    Span &operator +=(size_t offset) {
        orc_assert(this->size_ >= offset);
        this->data_ += offset;
        this->size_ -= offset;
        return *this;
    }

    Span &operator ++() {
        return *this += 1;
    }

    uint8_t operator [](size_t index) const {
        return this->data_[index];
    }

    void load(size_t offset, const Buffer &data) {
        orc_assert(offset <= this->size_);
        data.each([&](const uint8_t *data, size_t size) {
            orc_assert(this->size_ - offset >= size);
            Copy(this->data_ + offset, data, size);
            offset += size;
            return true;
        });
    }
};

template <typename Type_>
inline bool operator ==(const Span<Type_> &lhs, const Span<Type_> &rhs) {
    const auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

typedef Span<const char> View;

inline View operator ""_v(const char *data, size_t size) {
    return {data, size};
}

std::ostream &operator <<(std::ostream &out, const View &view);

std::optional<Range<>> Find(const View &data, const View &value);
std::tuple<View, View> Split(const View &value, const Range<> &range);

cppcoro::generator<View> Split(const View &value, const View &delimeter);

void Split(const View &value, const View &delimeter, const std::function<void (View, View)> &code);

class Region :
    public Buffer
{
  public:
    virtual const uint8_t *data() const = 0;
    size_t size() const override = 0;

    bool have(size_t value) const override {
        return value <= size();
    }

    bool each(const std::function<bool (const uint8_t *, size_t)> &code) const override {
        return code(data(), size());
    }

    uint8_t operator [](size_t index) const {
        return data()[index];
    }

    operator asio::const_buffer() const {
        return asio::const_buffer(data(), size());
    }

    Span<const uint8_t> span() const {
        return {data(), size()};
    }

    template <typename Type_>
    Type_ num() const {
        return Cast<Type_>::Load(data(), size());
    }

    unsigned nib(size_t index) const {
        orc_assert((index >> 1) < size());
        const auto value(data()[index >> 1]);
        if ((index & 0x1) == 0)
            return value >> 4;
        else
            return value & 0xf;
    }
};

class Mutable :
    public Region
{
  public:
    using Region::data;
    virtual uint8_t *data() = 0;

    Mutable &operator =(const Span<const uint8_t> &span) {
        orc_insist(span.size() == size());
        Copy(data(), span.data(), size());
        return *this;
    }

    Mutable &operator =(const Region &region) {
        operator =(region.span());
        return *this;
    }

    Mutable &operator =(const Buffer &buffer);

    using Region::span;
    Span<uint8_t> span() {
        return {data(), size()};
    }
};

class Segment final :
    public Span<const uint8_t>
{
  public:
    using Span<const uint8_t>::Span;

    Segment() = default;

    Segment(const Region &region) :
        Span(region.data(), region.size())
    {
    }

    Segment(const char *data, size_t size) :
        Span(reinterpret_cast<const uint8_t *>(data), size)
    {
    }

    Segment &operator =(const Region &region) {
        this->data_ = region.data();
        this->size_ = region.size();
        return *this;
    }

    operator asio::const_buffer() const {
        return {this->data_, this->size_};
    }
};

class Subset final :
    public Region
{
  private:
    const Segment segment_;

  public:
    Subset(const Segment &segment) :
        segment_(segment)
    {
    }

    Subset(const uint8_t *data, size_t size) :
        segment_(data, size)
    {
    }

    Subset(const char *data, size_t size) :
        segment_(data, size)
    {
    }

    template <typename Type_>
    Subset(const Type_ *value) :
        Subset(reinterpret_cast<const uint8_t *>(value), sizeof(Type_))
    {
        static_assert(std::is_pod<Type_>::value);
    }

    Subset(const Span<> &span) :
        Subset(span.data(), span.size())
    {
    }

    Subset(const std::string &data) :
        Subset(data.data(), data.size())
    {
    }

    Subset(const Region &region) :
        Subset(region.data(), region.size())
    {
    }

    const uint8_t *data() const override {
        return segment_.data();
    }

    size_t size() const override {
        return segment_.size();
    }

    Subset subset(size_t offset, size_t length) const {
        orc_insist(offset <= size());
        orc_insist(size() - offset >= length);
        return {data() + offset, length};
    }
};

template <size_t Size_>
class Bounded :
    public Region
{
  private:
    const uint8_t *data_;

  public:
    explicit Bounded(const uint8_t *data) :
        data_(data)
    {
    }

    Bounded(const std::array<uint8_t, Size_> &data) :
        Bounded(data.data())
    {
    }

    const uint8_t *data() const override {
        return data_;
    }

    size_t size() const override {
        return Size_;
    }

    template <size_t Skip_>
    auto skip() {
        static_assert(Skip_ <= Size_);
        return Bounded<Size_ - Skip_>(data() + Skip_);
    }
};

template <typename Data_>
class Strung final :
    public Region
{
  private:
    const Data_ data_;

  public:
    explicit Strung(Data_ data) :
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
    public Mutable
{
  protected:
    std::array<uint8_t, Size_> data_;

  public:
    Data() = default;

    Data(const Span<const uint8_t> &span) {
        operator =(span);
    }

    Data(const Region &region) {
        operator =(region);
    }

    Data(const Buffer &buffer) {
        operator =(buffer);
    }

    Data(const std::array<uint8_t, Size_> &data) :
        data_(data)
    {
    }

    const uint8_t *data() const override {
        return data_.data();
    }

    uint8_t *data() override {
        return data_.data();
    }

    size_t size() const override {
        return Size_;
    }

    bool operator <(const Data<Size_> &rhs) const {
        return data_ < rhs.data_;
    }

    template <size_t Skip_>
    auto skip() {
        static_assert(Skip_ <= Size_);
        return Bounded<Size_ - Skip_>(data() + Skip_);
    }
};

template <size_t Size_>
inline bool operator ==(const Data<Size_> &lhs, const Data<Size_> &rhs) {
    return memcmp(lhs.data(), rhs.data(), Size_) == 0;
}

template <size_t Size_>
class Brick final :
    public Data<Size_>
{
  public:
    static const size_t Size = Size_;

  public:
    using Data<Size_>::Data;
    using Data<Size_>::operator =;

    Brick() = default;

    Brick(const std::string &data) :
        Brick(data.data(), data.size())
    {
    }

    explicit constexpr Brick(std::initializer_list<uint8_t> list) noexcept {
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

template <size_t Size_>
Brick<Size_> Zero() {
    Brick<Size_> brick;
    memset(brick.data(), 0, brick.size());
    return brick;
}

template <typename Type_, bool Arithmetic_ = std::is_arithmetic<Type_>::value>
class Number;

template <typename Type_>
class Number<Type_, true> final :
    public Mutable
{
  private:
    Type_ value_;

  public:
    Number() = default;

    constexpr Number(Type_ value) noexcept :
        value_(boost::endian::native_to_big(value))
    {
    }

    Number(const Brick<sizeof(Type_)> &brick) :
        Number(brick.template num<Type_>())
    {
    }

    operator Type_() const {
        return boost::endian::big_to_native(value_);
    }

    operator Brick<sizeof(Type_)>() const {
        return Brick<sizeof(Type_)>(static_cast<const Region &>(*this));
    }

    const uint8_t *data() const override {
        return reinterpret_cast<const uint8_t *>(&value_);
    }

    uint8_t *data() override {
        return reinterpret_cast<uint8_t *>(&value_);
    }

    size_t size() const override {
        return sizeof(Type_);
    }

    bool zero() const override {
        return value_ != 0;
    }
};

template <unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_>
class Number<boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>>, false> final :
    public Data<(Bits_ >> 3)>
{
  public:
    // NOLINTNEXTLINE (modernize-use-equals-default)
    using Data<(Bits_ >> 3)>::Data;

    Number(boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>> value, uint8_t pad = 0) {
        for (auto i(boost::multiprecision::export_bits(value, this->data_.rbegin(), 8, false)), e(this->data_.rend()); i != e; ++i)
            *i = pad;
    }

    Number(const std::string &value) :
        Number(boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>>(value))
    {
    }

    operator Brick<(Bits_ >> 3)>() const {
        return Brick<(Bits_ >> 3)>(static_cast<const Region &>(*this));
    }
};

class Beam :
    public Mutable
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
        data_(nullptr)
    {
    }

    explicit Beam(size_t size) :
        size_(size),
        data_(new uint8_t[size_])
    {
    }

    Beam(const void *data, size_t size) :
        Beam(size)
    {
        Copy(data_, data, size_);
    }

    Beam(const std::string &data) :
        Beam(data.data(), data.size())
    {
    }

    explicit Beam(const Buffer &buffer);

    explicit Beam(const Beam &rhs) :
        Beam(static_cast<const Buffer &>(rhs))
    {
    }

    Beam(Beam &&rhs) noexcept :
        size_(rhs.size_),
        data_(rhs.data_)
    {
        rhs.size_ = 0;
        rhs.data_ = nullptr;
    }

    virtual ~Beam() {
        destroy();
    }

    Beam &operator =(const Beam &) = delete;

    Beam &operator =(Beam &&rhs) noexcept {
        destroy();
        size_ = rhs.size_;
        data_ = rhs.data_;
        rhs.size_ = 0;
        rhs.data_ = nullptr;
        return *this;
    }

    void clear() {
        destroy();
        size_ = 0;
        data_ = nullptr;
    }

    const uint8_t *data() const override {
        return data_;
    }

    uint8_t *data() override {
        return data_;
    }

    size_t size() const override {
        return size_;
    }

    Subset subset(size_t offset, size_t length) const {
        orc_insist(offset <= size());
        orc_insist(size() - offset >= length);
        return {data() + offset, length};
    }

    uint8_t &operator [](size_t index) {
        return data_[index];
    }
};

Beam Bless(const std::string &data);

template <typename Data_>
inline bool operator ==(const Region &lhs, const std::string &rhs) {
    const auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

template <size_t Size_>
inline bool operator ==(const Region &lhs, const Data<Size_> &rhs) {
    const auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

inline bool operator ==(const Region &lhs, const Segment &rhs) {
    const auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

inline bool operator ==(const Region &lhs, const Region &rhs) {
    const auto size(lhs.size());
    return size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) == 0;
}

bool operator ==(const Region &lhs, const Buffer &rhs);

template <typename Buffer_>
inline bool operator !=(const Region &lhs, const Buffer_ &rhs) {
    return !(lhs == rhs);
}

inline bool operator <(const Region &lhs, const Region &rhs) {
    const auto size(lhs.size());
    return size < rhs.size() || size == rhs.size() && memcmp(lhs.data(), rhs.data(), size) < 0;
}

class Nothing final :
    public Region
{
  public:
    const uint8_t *data() const override {
        return nullptr;
    }

    size_t size() const override {
        return 0;
    }
};

inline bool Each(const Buffer &buffer, const std::function<bool (const uint8_t *, size_t)> &code) {
    return buffer.each(code);
}

template <size_t Size_>
inline bool Each(const char (&data)[Size_], const std::function<bool (const uint8_t *, size_t)> &code) {
    return Subset(data, Size_ - 1).each(code);
}

template <typename Type_>
inline typename std::enable_if<std::is_arithmetic<Type_>::value, bool>::type Each(const Type_ &value, const std::function<bool (const uint8_t *, size_t)> &code) {
    return Number<Type_>(value).each(code);
}

template <unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_>
inline typename std::enable_if<Bits_ % 8 == 0, bool>::type Each(const boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>> &value, const std::function<bool (const uint8_t *, size_t)> &code) {
    return Number<boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>>>(value).each(code);
}

template <typename... Args_>
static bool Each(const std::tuple<Args_...> &tuple, const std::function<bool (const uint8_t *, size_t)> &code) {
    bool each(true);
    boost::mp11::tuple_for_each(tuple, [&](const auto &value) {
        each &= Each(value, code);
    }); return each;
}

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

    bool each(const std::function<bool (const uint8_t *, size_t)> &code) const override {
        return Each(buffers_, code);
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
    std::vector<Segment> segments_;

  public:
    Sequence(const Buffer &buffer) :
        segments_([&]() {
            size_t count(0);
            buffer.each([&](const uint8_t *data, size_t size) {
                ++count;
                return true;
            });
            return count;
        }())
    {
        auto i(segments_.begin());
        buffer.each([&](const uint8_t *data, size_t size) {
            *(i++) = Segment(data, size);
            return true;
        });
    }

    Sequence(Sequence &&sequence) noexcept :
        segments_(std::move(sequence.segments_))
    {
    }

    Sequence(const Sequence &sequence) :
        segments_(sequence.segments_)
    {
    }

    auto begin() const {
        return segments_.begin();
    }

    auto end() const {
        return segments_.end();
    }

    bool each(const std::function<bool (const uint8_t *, size_t)> &code) const override {
        for (auto i(begin()), e(end()); i != e; ++i)
            if (!code(i->data(), i->size()))
                return false;
        return true;
    }
};

template <size_t Size_>
class Pad :
    public Data<Size_>
{
  public:
    Pad() {
        this->data_.fill(0);
    }
};

class Window :
    public Buffer
{
  private:
    size_t count_;
    // XXX: I'm just being lazy here. :/
    std::unique_ptr<Segment[]> segments_;

    const Segment *segment_;
    size_t offset_;

  public:
    Window() :
        count_(0),
        segment_(nullptr),
        offset_(0)
    {
    }

    Window(const Buffer &buffer) :
        count_([&]() {
            size_t count(0);
            buffer.each([&](const uint8_t *data, size_t size) {
                ++count;
                return true;
            });
            return count;
        }()),

        segments_(new Segment[count_]),

        segment_(segments_.get()),
        offset_(0)
    {
        auto i(segments_.get());
        buffer.each([&](const uint8_t *data, size_t size) {
            *(i++) = Segment(data, size);
            return true;
        });
    }

    Window(const Segment &segment) :
        count_(1),
        segments_(new Segment[count_]),
        segment_(segments_.get()),
        offset_(0)
    {
        segments_.get()[0] = segment;
    }

    Window(const Window &window) :
        Window([](const Buffer &buffer) -> const Buffer & {
            return buffer;
        }(window))
    {
    }

    Window(Window &&rhs) = default;
    Window &operator =(Window &&rhs) = default;

    bool each(const std::function<bool (const uint8_t *, size_t)> &code) const override {
        auto here(segment_);
        const auto rest(segments_.get() + count_ - here);
        if (rest == 0)
            return true;

        size_t i;
        if (offset_ == 0)
            i = 0;
        else {
            i = 1;
            if (!code(here->data() + offset_, here->size() - offset_))
                return false;
        }

        for (; i != rest; ++i)
            if (!code(here[i].data(), here[i].size()))
                return false;

        return true;
    }

    void Stop() {
        orc_assert(done());
    }

    template <typename Code_>
    void Take(size_t need, Code_ &&code) {
        for (auto rest(segments_.get() + count_ - segment_); need != 0; offset_ = 0, ++segment_, --rest) {
            orc_assert(rest != 0);

            const auto data(segment_->data());
            auto size(std::min(need, segment_->size() - offset_));
            while (size != 0) {
                const auto writ(code(data + offset_, size));
                orc_insist(writ <= size);
                offset_ += writ;
                need -= writ;
                if (need == 0)
                    return;
                size -= writ;
            }
        }
    }

    void Take(uint8_t *here, size_t size) {
        Take(size, [&](const uint8_t *data, size_t size) {
            Copy(here, data, size);
            here += size;
            return size;
        });
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

    template <typename Type_>
    void Take(Number<Type_> &value) {
        Take(value.data(), value.size());
    }

    Beam Take(size_t size) {
        orc_assert(have(size));
        Beam beam(size);
        Take(beam.data(), beam.size());
        return beam;
    }

    template <typename Type_>
    void Take(Type_ *value) {
        static_assert(std::is_pod<Type_>::value);
        Take(reinterpret_cast<uint8_t *>(value), sizeof(Type_));
    }

    void Skip(size_t size) {
        Take(size, [&](const uint8_t *data, size_t size) {
            return size;
        });
    }

    void Zero(size_t size) {
        Take(size, [&](const uint8_t *data, size_t size) {
            for (decltype(size) i(0); i != size; ++i)
                orc_assert(data[i] == 0);
            return size;
        });
    }
};

class Rest final :
    public Window
{
  private:
    Beam data_;

  public:
    Rest() = default;

    Rest(Window &&window, Beam &&data) :
        Window(std::move(window)),
        data_(std::move(data))
    {
    }
};


class Builder :
    public Region,
    public std::basic_string<uint8_t>
{
  public:
    const uint8_t *data() const override {
        return std::basic_string<uint8_t>::data();
    }

    size_t size() const override {
        return std::basic_string<uint8_t>::size();
    }

    void operator +=(const Buffer &buffer) {
        buffer.each([&](const uint8_t *data, size_t size) {
            append(data, size);
            return true;
        });
    }
};

template <typename... Args_>
struct Building;

template <>
struct Building<> {
static void Build(Builder &builder) {
} };

template <typename Next_, typename... Rest_>
struct Building<Next_, Rest_...> {
static void Build(Builder &builder, Next_ &&next, Rest_ &&...rest) {
    Each(std::forward<Next_>(next), [&](const uint8_t *data, size_t size) {
        builder += Beam(data, size);
        return true;
    });
    Building<Rest_...>::Build(builder, std::forward<Rest_>(rest)...);
} };

template <typename... Args_>
void Build(Builder &builder, Args_ &&...args) {
    Building<Args_...>::Build(builder, std::forward<Args_>(args)...);
}


template <size_t Index_, typename Next_, typename Enable_, typename... Taking_>
struct Taking;

template <size_t Index_, typename... Taking_>
struct Taker;

template <size_t Index_, size_t Size_, typename... Taking_>
struct Taking<Index_, Pad<Size_>, void, Taking_...> final {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    window.Zero(Size_);
    return Taker<Index_, Taking_...>::Take(tuple, window, std::forward<Buffer_>(buffer));
} };

template <size_t Index_, size_t Size_, typename... Taking_>
struct Taking<Index_, Brick<Size_>, void, Taking_...> final {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    window.Take(std::get<Index_>(tuple));
    return Taker<Index_ + 1, Taking_...>::Take(tuple, window, std::forward<Buffer_>(buffer));
} };

template <size_t Index_, typename Type_, typename... Taking_>
struct Taking<Index_, Number<Type_>, void, Taking_...> final {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    window.Take(std::get<Index_>(tuple));
    return Taker<Index_ + 1, Taking_...>::Take(tuple, window, std::forward<Buffer_>(buffer));
} };

template <size_t Index_, unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_, typename... Taking_>
struct Taking<Index_, boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>>, typename std::enable_if<Bits_ % 8 == 0>::type, Taking_...> final {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    Brick<Bits_ / 8> brick;
    window.Take(brick);
    std::get<Index_>(tuple) = brick.template num<boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>>>();
    return Taker<Index_ + 1, Taking_...>::Take(tuple, window, std::forward<Buffer_>(buffer));
} };

template <size_t Index_, typename Next_, typename... Taking_>
struct Taking<Index_, Next_, typename std::enable_if<std::is_arithmetic<Next_>::value>::type, Taking_...> {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    Brick<sizeof(Next_)> brick;
    window.Take(brick);
    std::get<Index_>(tuple) = brick.template num<Next_>();
    return Taker<Index_ + 1, Taking_...>::Take(tuple, window, std::forward<Buffer_>(buffer));
} };

template <size_t Index_>
struct Taking<Index_, Window, void> {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    static_assert(!std::is_rvalue_reference<Buffer_ &&>::value);
    std::get<Index_>(tuple) = std::move(window);
    return false;
} };

template <size_t Index_>
struct Taking<Index_, Rest, void> {
template <typename Tuple_>
static bool Take(Tuple_ &tuple, Window &window, Beam &&buffer) {
    std::get<Index_>(tuple) = Rest(std::move(window), std::move(buffer));
    return false;
} };

template <size_t Index_>
struct Taking<Index_, Beam, void> {
template <typename Tuple_>
static bool Take(Tuple_ &tuple, Window &window, Beam &&buffer) {
    std::get<Index_>(tuple) = Beam(window);
    return false;
} };

template <size_t Index_, typename Next_, typename... Taking_>
struct Taker<Index_, Next_, Taking_...> {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    return Taking<Index_, Next_, void, Taking_...>::Take(tuple, window, std::forward<Buffer_>(buffer));
} };

template <size_t Index_>
struct Taker<Index_> {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    return true;
} };

template <typename Tuple_, typename... Taking_>
struct Taken;

template <typename Tuple_, typename Type_, typename... Taking_>
struct Taken<Tuple_, Type_, Taking_...> {
    typedef typename Taken<decltype(std::tuple_cat(Tuple_(), std::tuple<Type_>())), Taking_...>::type type;
};

template <typename Tuple_, size_t Size_, typename... Taking_>
struct Taken<Tuple_, Pad<Size_>, Taking_...> {
    typedef typename Taken<Tuple_, Taking_...>::type type;
};

template <typename Tuple_>
struct Taken<Tuple_> {
    typedef Tuple_ type;
};

template <size_t Index_, typename... Nested_, typename... Taking_>
struct Taking<Index_, std::tuple<Nested_...>, void, Taking_...> {
template <typename Tuple_, typename Buffer_>
static bool Take(Tuple_ &tuple, Window &window, Buffer_ &&buffer) {
    const auto stop(Taker<0, Nested_...>::Take(std::get<Index_>(tuple), window, std::forward<Buffer_>(buffer)));
    orc_assert(stop);
    return Taker<Index_ + 1, Taking_...>::Take(tuple, window, std::forward<Buffer_>(buffer));
} };

template <typename... Taking_, typename Buffer_>
auto Take(Buffer_ &&buffer) {
    typename Taken<std::tuple<>, Taking_...>::type tuple;
    Window window(buffer);
    if (Taker<0, Taking_...>::Take(tuple, window, std::forward<Buffer_>(buffer)))
        window.Stop();
    return tuple;
}

template <typename Code_>
bool Chunk(const uint8_t *data, size_t size, Code_ code) noexcept(noexcept(code(nullptr, 0))) {
    while (size != 0) {
        const auto writ(code(data, size));
        if (writ == 0)
            return false;
        orc_insist(writ <= size);
        size -= writ;
    }

    return true;
}

}

#endif//ORCHID_BUFFER_HPP
