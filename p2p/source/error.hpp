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


#ifndef ORCHID_ERROR_HPP
#define ORCHID_ERROR_HPP

#include <exception>
#include <iostream>
#include <sstream>
#include <string>

#include "category.hpp"
#include "log.hpp"

namespace orc {
class Error final :
    public std::exception
{
  public:
    std::string what_;

    Error() = default;
    Error(Error &&error) = default;

    [[nodiscard]] const char *what() const noexcept override {
        return what_.c_str();
    }

    template <typename Type_>
    Error operator <<(const Type_ &value) && {
        std::ostringstream data;
        data << value;
        what_ += data.str();
        return std::move(*this);
    }
}; }

#define orc_insist_(code, text) do { \
    if ((code)) break; \
    orc_log(orc_Log(), text << std::endl); \
    std::terminate(); \
} while (false)

#define orc_insist(code) \
    orc_insist_(code, "orc_insist(" #code ")")

#define orc_throw(text) do { \
    if (orc::Verbose) \
        orc_log(orc_Log() << "throw ", text << std::endl); \
    throw orc_log(orc::Error(), text); \
} while (false)

#define orc_adapt(error) do { \
    const auto code(error.code()); \
    if (code.category() == orchid_category()) \
        std::rethrow_exception(Category::Convert(code.value())); \
    auto what(error.what()); \
    orc_insist(what != nullptr); \
    orc_insist(*what != '\0'); \
    orc_throw(what); \
} while (false)

#define orc_assert_(code, text) do { \
    if ((code)) break; \
    orc_throw(text); \
} while (false)

#define orc_assert(code) \
    orc_assert_(code, "orc_assert(" #code ")")

#define orc_catch(code) \
    catch (const std::exception &error) { \
        orc_log(orc_Log(), "handled error " << error.what() << std::endl); \
    code } catch (...) { code }

#define orc_ignore(code) \
    ({ bool _failed(false); try code \
        orc_catch({ _failed = true; }) \
    _failed; })

#define orc_except(code) \
    try code catch (...) { \
        orc_log(orc_Log(), "orc_except(" #code ")" << std::endl); \
        std::terminate(); \
    }

#define orc_stack(code, text) \
    catch (orc::Error &error) { code \
        throw orc_log(std::move(error) << ' ', text); \
    } catch (const std::exception &error) { code \
        throw orc_log(orc::Error() << error.what() << ' ', text); \
    }

#define orc_block(code, text) do { \
    if (orc::Verbose) \
        orc_log(orc_Log(), "++ " << text << std::endl); \
    try code orc_stack({ \
        if (orc::Verbose) \
            orc_log(orc_Log(), "-- " << text << std::endl); \
    }, text) \
    if (orc::Verbose) \
        orc_log(orc_Log(), "-- " << text << std::endl); \
} while (false)

#define orc_value(ret, code, text) [&]() -> decltype(code) { \
    if (orc::Verbose) \
        orc_log(orc_Log(), "++ " << text << std::endl); \
    try { ret (code); } orc_stack({ \
        if (orc::Verbose) \
            orc_log(orc_Log(), "-- " << text << std::endl); \
    }, text) \
    if (orc::Verbose) \
        orc_log(orc_Log(), "-- " << text << std::endl); \
}()

#endif//ORCHID_ERROR_HPP
