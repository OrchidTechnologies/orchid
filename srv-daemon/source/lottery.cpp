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


#include "lottery.hpp"
#include "sleep.hpp"
#include "time.hpp"

namespace orc {

std::ostream &operator <<(std::ostream &out, const Pot &pot) {
    return out << std::dec << "Pot{.amount_=" << pot.amount_ << ", .escrow_=" << pot.escrow_ << ", .warned_=" << pot.warned_ << "}";
}

void Lottery::Open() {
    Spawn([this]() mutable noexcept -> task<void> {
        for (auto height(co_await Height());;) try {
            co_await Sleep(10*1000);
            auto next(co_await Height());
            if (next <= height)
                continue;
            co_await Scan(height + 1, next + 1);
            height = next;
        } orc_catch()
    }, __FUNCTION__);
}

task<uint256_t> Lottery::Check(const Address &signer, const Address &funder, const Address &recipient) {
    const auto hash(Hash(signer, funder));

    { const auto locked(locked_());
        const auto i(locked->pots_.find(hash));
        if (i != locked->pots_.end())
            co_return i->second.first.usable();
    }

    const auto height(co_await Height());
    const auto pot(co_await Read(height, signer, funder, recipient));

    { const auto locked(locked_());
        auto &i(locked->pots_[hash]);
        if (i.second < height)
            i = {pot, height};
        co_return i.first.usable();
    }
}

}
