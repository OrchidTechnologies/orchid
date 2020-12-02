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


#include <map>
#include <mutex>

#include "category.hpp"
#include "error.hpp"

namespace orc {

static std::mutex mutex_;
static std::map<int, std::exception_ptr> errors_;
static int index_(0);

std::string Category::message(int index) const {
    try {
        std::rethrow_exception(Convert(index));
    } catch (const std::exception &error) {
        return error.what();
    }
}

std::exception_ptr Category::Convert(int index) noexcept {
    std::unique_lock<std::mutex> lock(mutex_);
    if (const auto error = errors_.extract(index))
        return error.mapped();
    orc_insist(false);
}

boost::system::error_code Category::Convert(const std::exception_ptr &error) noexcept {
    std::unique_lock<std::mutex> lock(mutex_);
    // XXX: clang-tidy might need fixing, as this just bans ?:
    // NOLINTNEXTLINE (readability-implicit-bool-conversion)
    while (!errors_.try_emplace(++index_ ?: ++index_, error).second);
    return {index_, orchid_category()};
}

}
