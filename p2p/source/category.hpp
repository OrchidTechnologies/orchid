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


#ifndef ORCHID_CATEGORY_HPP
#define ORCHID_CATEGORY_HPP

#include <boost/system/error_code.hpp>

namespace orc {

class Category :
    public boost::system::error_category
{
  public:
    const char *name() const noexcept override {
        return "orchid";
    }

    std::string message(int index) const override;

    static std::exception_ptr Convert(int index) noexcept;
    static boost::system::error_code Convert(const std::exception_ptr &error) noexcept;
};

template <typename>
struct Categories {
    static constexpr Category category_{};
};

}

constexpr const boost::system::error_category &orchid_category() noexcept {
    return orc::Categories<void>::category_;
}

#endif//ORCHID_CATEGORY_HPP
