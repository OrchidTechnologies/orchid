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


#include "risc0.hpp"

namespace eth {

class Nested {
  private:
    const uint8_t *here_;
    const uint8_t *stop_;

    size_t more(size_t meta) {
        size_t writ(0);
        cyk_assert(size() >= meta);
        memcpy(reinterpret_cast<uint8_t *>(&writ) + sizeof(size_t) - meta, here_, meta);
        here_ += meta;
        return __builtin_bswap32(writ);
    }

  public:
    Nested(const uint8_t *data, const uint8_t *stop) :
        here_(data), stop_(stop)
    {
        cyk_assert(size() >= 1);
        size_t writ(*here_++);

        if (writ > 0xf7)
            writ = more(writ - 0xf7);
        else {
            cyk_assert(writ >= 0xc0);
            writ = writ - 0xc0;
        }

        cyk_assert(size() == writ);
    }

    Nested(const uint8_t *data, size_t size) :
        Nested(data, data + size) {}

    const uint8_t *data() const {
        return here_; }
    size_t size() const {
        return stop_ - here_; }
    bool done() const {
        return size() == 0; }

    size_t next() {
        cyk_assert(size() >= 1);
        const auto writ(*here_);
        if (writ < 0x80)
            return 1;
        ++here_;

        if (writ <= 0xb7)
            return writ - 0x80;
        else {
            cyk_assert(writ < 0xc0);
            return more(writ - 0xb7);
        }
    }

    void bump(size_t size) {
        here_ += size;
    }

    void skip(size_t count) {
        for (size_t i(0); i != count; ++i) {
            const auto writ(next());
            cyk_assert(size() >= writ);
            here_ += writ;
        }
    }

    void copy(void *data, size_t writ) {
        cyk_assert(size() >= writ);
        memcpy(data, here_, writ);
        here_ += writ;
    }

    template <typename Type_>
    void read(Type_ *data) {
        cyk_assert(next() == sizeof(*data));
        copy(data, sizeof(*data));
    }
};

}
