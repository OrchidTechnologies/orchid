/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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


#include <iomanip>

#include "buffer.hpp"
#include "fit.hpp"
#include "scope.hpp"

namespace orc {

std::atomic<uint64_t> copied_(0);

size_t Buffer::size() const {
    size_t value(0);
    each([&](const uint8_t *data, size_t size) {
        value += size;
        return true;
    });
    return value;
}

bool Buffer::have(size_t value) const {
    return !each([&](const uint8_t *data, size_t size) {
        if (value <= size)
            return false;
        value -= size;
        return true;
    }) || value == 0;
}

bool Buffer::done() const {
    return each([&](const uint8_t *data, size_t size) {
        return size == 0;
    });
}

bool Buffer::zero() const {
    return each([&](const uint8_t *data, size_t size) {
        for (decltype(size) i(0); i != size; ++i)
            if (data[i] != 0)
                return false;
        return true;
    });
}

std::vector<uint8_t> Buffer::vec() const {
    std::vector<uint8_t> value;
    value.resize(size());
    copy(&value[0], value.size());
    return value;
}

std::string Buffer::str() const {
    std::string value;
    value.resize(size());
    copy(&value[0], value.size());
    return value;
}

std::string Buffer::hex(bool prefix) const {
    std::ostringstream value;
    if (prefix)
        value << "0x";
    value << std::hex << std::setfill('0');
    each([&](const uint8_t *data, size_t size) {
        for (size_t i(0), e(size); i != e; ++i)
            value << std::setw(2) << unsigned(data[i]);
        return true;
    });
    return value.str();
}

void Buffer::copy(uint8_t *data, size_t size) const {
    auto here(data);

    each([&](const uint8_t *next, size_t writ) {
        orc_assert(data + size - here >= writ);
        Copy(here, next, writ);
        here += writ;
        return true;
    });

    orc_assert(here == data + size);
}

Snipped Buffer::snip(size_t length) const {
    return {*this, length};
}

std::ostream &operator <<(std::ostream &out, const Buffer &buffer) {
    const auto flags(out.flags());
    _scope({ out.flags(flags); });

    out << std::setfill('0');
    out << std::setbase(16);

    out << '{';
    bool comma(false);
    buffer.each([&](const uint8_t *data, size_t size) {
        if (comma)
            out << ',';
        else
            comma = true;
        for (size_t i(0); i != size; ++i)
            out << std::setw(2) << int(data[i]);
        return true;
    });
    out << '}';
    return out;
}

// XXX: I don't think the return value of this is correct, but I'm not using it today
bool Snipped::each(const std::function<bool (const uint8_t *, size_t)> &code) const {
    size_t rest(size_);
    return data_.each([&](const uint8_t *data, size_t size) {
        if (rest > size) {
            rest -= size;
            return code(data, size);
        } else {
            code(data, rest);
            return false;
        }
    });
}

std::ostream &operator <<(std::ostream &out, const View &view) {
    out.write(view.data(), Fit(view.size()));
    return out;
}

#ifdef _WIN32
const char *memmem(const char *haystack, size_t haystacklen, const char *needle, size_t needlelen) {
    const auto value(std::search(haystack, haystack + haystacklen, needle, needle + needlelen));
    return value == haystack + haystacklen ? nullptr : value;
}
#endif

std::optional<Range<>> Find(const View &data, const View &value) {
    if (const auto start = static_cast<const char *>(memmem(data.data(), data.size(), value.data(), value.size())))
        return std::optional<Range<>>(std::in_place, start - data.data(), value.size());
    return {};
}

std::tuple<View, View> Split(const View &value, const Range<> &range) {
    const auto data(value.data());
    const auto size(value.size());
    orc_assert(range.data() <= size);
    orc_assert(range.size() <= size - range.data());
    const auto right(range.data() + range.size());
    return {View(data, range.data()), View(data + right, size - right)};
}

cppcoro::generator<View> Split(const View &value, std::string delimeter) {
    for (auto data(value.data()), stop(data + value.size());; ) {
        // XXX: this clang-tidy check should not trigger on ?:
        // NOLINTNEXTLINE (readability-implicit-bool-conversion)
        const auto next(static_cast<const char *>(memmem(data, stop - data, delimeter.data(), delimeter.size())) ?: stop);
        co_yield View(data, next - data);
        if (next == stop)
            break;
        data = next + delimeter.size();
    }
}

void Split(const View &value, const View &delimeter, const std::function<void (View, View)> &code) {
    const auto data(value.data());
    const auto before(static_cast<const char *>(memmem(data, value.size(), delimeter.data(), delimeter.size())));
    orc_assert(before != nullptr);
    const auto after(before + delimeter.size());
    code(View(data, before - data), View(after, data + value.size() - after));
}

std::string Join(const std::string &delimeter, const std::vector<std::string> &args) {
    std::ostringstream data;

    bool comma(false);
    for (const auto &arg : args) {
        if (comma)
            data << delimeter;
        else
            comma = true;
        data << arg;
    }

    return data.str();
}

Mutable &Mutable::operator =(const Buffer &buffer) {
    auto here(data());
    size_t rest(size());

    buffer.each([&](const uint8_t *data, size_t size) {
        orc_assert(rest >= size);
        Copy(here, data, size);
        here += size;
        rest -= size;
        return true;
    });

    orc_assert(rest == 0);
    return *this;
}

Beam::Beam(const Buffer &buffer) :
    Beam(buffer.size())
{
    buffer.copy(data_, size_);
}

char Hex(uint8_t value) {
    // XXX: maybe I need to assert that value < 16 ;P
    return char((value < 10 ? '0' : 'a' - 10) + value);
}

uint8_t Bless(char value) {
    if (value >= '0' && value <= '9')
        return value - '0';
    if (value >= 'a' && value <= 'f')
        return value - 'a' + 10;
    if (value >= 'A' && value <= 'F')
        return value - 'A' + 10;
    orc_assert_(false, "'" << value << "' is not hex");
}

void Bless(const std::string_view &value, Mutable &region) {
    if (value == "0x0") return region.size(0);

    size_t size(value.size());
    orc_assert_((size & 1) == 0, "odd-length hex data in \"" << value << "\"");
    size >>= 1;

    size_t offset;
    if (value[0] != '0' || value[1] != 'x') {
        offset = 0;
    } else {
        offset = 2;
        --size;
    }

    region.size(size);
    auto data(region.data());
    for (size_t i(0); i != size; ++i)
        data[i] = uint8_t((Bless(value[offset + i * 2]) << 4) + Bless(value[offset + i * 2 + 1]));
}

bool operator ==(const Region &lhs, const Buffer &rhs) {
    auto here(lhs.data());
    auto left(lhs.size());

    return rhs.each([&](const uint8_t *data, size_t size) {
        if (size > left || memcmp(here, data, size) != 0)
            return false;
        here += size;
        left -= size;
        return true;
    }) && here == lhs.data() + lhs.size();
}

}
