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


#ifndef ORCHID_DATABASE_HPP
#define ORCHID_DATABASE_HPP

#include <sqlite3.h>

#include "shared.hpp"

#define orc_sqlstep(expr) ({ \
    auto _value(expr); \
    orc_assert_(_value == 0 || _value >= 100 && _value < 200, "orc_sqlcall(" #expr ") " << _value << ":" << sqlite3_errmsg(database_)); \
_value; })

#define orc_sqlcall(expr) \
    orc_assert(orc_sqlstep(expr) == SQLITE_OK)

namespace orc {

class Database {
  private:
    sqlite3 *database_;

  public:
    Database(const std::string &path) {
        orc_sqlcall(sqlite3_open_v2(path.c_str(), &database_, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nullptr));
    }

    ~Database() { try {
        orc_sqlcall(sqlite3_close(database_));
    } catch (...) {
        orc_insist(false);
    } }

    operator sqlite3 *() const {
        return database_;
    }
};

template <typename Results_, typename... Args_>
class Statement {
  private:
    Database &database_;
    sqlite3_stmt *statement_;

    template <unsigned Index_>
    void Bind() {
    }

#define orc_bind(name, type, ...) \
    template <unsigned Index_, typename... Rest_> \
    void Bind(type value, Rest_ &&...rest) { \
        orc_sqlcall(sqlite3_bind_ ## name(statement_, Index_, ## __VA_ARGS__)); \
        return Bind<Index_ + 1>(std::forward<Rest_>(rest)...); \
    }

    orc_bind(double, double, value)
    orc_bind(int, int, value)
    orc_bind(int, uint, value)
    orc_bind(int64, sqlite3_int64, value)
    orc_bind(null, nullptr_t)

    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(text, const char *, value, -1, SQLITE_TRANSIENT)
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(text, const std::string &, value.c_str(), value.size(), SQLITE_TRANSIENT)
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(text, const std::string_view, value.data(), value.size(), SQLITE_TRANSIENT)

  public:
    Statement() :
        statement_(nullptr)
    {
    }

    Statement(Database &database, const char *code) :
        database_(database)
    {
        orc_sqlcall(sqlite3_prepare_v2(database_, code, -1, &statement_, nullptr));
    }

    ~Statement() { try {
        if (statement_ != nullptr)
            orc_sqlcall(sqlite3_finalize(statement_));
    } catch (...) {
        orc_insist(false);
    } }

    operator sqlite3_stmt *() const {
        return statement_;
    }

    Results_ operator ()(const Args_ &...args) {
        orc_sqlcall(sqlite3_reset(statement_));
        orc_sqlcall(sqlite3_clear_bindings(statement_));
        Bind<1>(args...);
        return Results_(database_, *this);
    }
};

class None {
  public:
    None(Database &database_, sqlite3_stmt *statement) {
        orc_assert(orc_sqlstep(sqlite3_step(statement)) == SQLITE_DONE);
    }
};

class Last final {
  private:
    sqlite3_int64 value_;

  public:
    Last(Database &database_, sqlite3_stmt *statement) {
        orc_assert(orc_sqlstep(sqlite3_step(statement)) == SQLITE_DONE);
        value_ = sqlite3_last_insert_rowid(database_);
    }

    operator sqlite3_int64() const {
        return value_;
    }
};

class Skip final {
  public:
    Skip(Database &database_, sqlite3_stmt *statement) {
        orc_assert(orc_sqlstep(sqlite3_step(statement)) == SQLITE_ROW);
        orc_assert(orc_sqlstep(sqlite3_step(statement)) == SQLITE_DONE);
    }
};

template <typename... Columns_>
class One final :
    public std::tuple<Columns_...>
{
  public:
    One(Database &database_, sqlite3_stmt *statement) {
        orc_assert(orc_sqlstep(sqlite3_step(statement)) == SQLITE_ROW);
        // XXX: implement this abstraction correctly
        std::get<0>(*this) = sqlite3_column_int64(statement, 0);
        orc_assert(orc_sqlstep(sqlite3_step(statement)) == SQLITE_DONE);
    }
};

}

#endif//ORCHID_DATABASE_HPP
