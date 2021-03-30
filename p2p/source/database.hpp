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


#ifndef ORCHID_DATABASE_HPP
#define ORCHID_DATABASE_HPP

#include <sqlite3.h>

#include "buffer.hpp"
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
    Database(const std::string &path, bool readonly = false) {
        orc_sqlcall(sqlite3_open_v2(path.c_str(), &database_, readonly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, nullptr));
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

template <auto Results_, typename... Args_>
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
    orc_bind(int, unsigned, value)
    orc_bind(int64, sqlite3_int64, value)
    orc_bind(null, nullptr_t)

    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(blob, const std::vector<uint8_t> &, value.data(), value.size(), SQLITE_TRANSIENT)
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(blob, const Region &, value.data(), value.size(), SQLITE_TRANSIENT)

    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(text, const char *, value, -1, SQLITE_TRANSIENT)
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(text, const std::string &, value.c_str(), value.size(), SQLITE_TRANSIENT)
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(text, const std::string_view &, value.data(), value.size(), SQLITE_TRANSIENT)
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(text, const View &, value.data(), value.size(), SQLITE_TRANSIENT)

    // XXX: maybe this is supposed to be size() * 2?
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    orc_bind(text16, const std::u16string &, value.data(), value.size(), SQLITE_TRANSIENT)

    template <unsigned Index_, typename Type_, typename... Rest_>
    void Bind(const std::optional<Type_> &value, Rest_ &&...rest) {
        if (value)
            return Bind<Index_>(*value, std::forward<Rest_>(rest)...);
        orc_sqlcall(sqlite3_bind_null(statement_, Index_));
        return Bind<Index_ + 1>(std::forward<Rest_>(rest)...);
    }

  public:
    Statement(Database &database, const char *code) :
        database_(database)
    {
        // XXX: evaluate using SQLITE_PREPARE_PERSISTENT and sqlite3_prepare_v3
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

    auto operator ()(const Args_ &...args) {
        orc_sqlcall(sqlite3_reset(statement_));
        orc_sqlcall(sqlite3_clear_bindings(statement_));
        Bind<1>(args...);
        return Results_(database_, *this);
    }
};


template <typename Type_>
struct Column;

template <>
struct Column<double> {
static double Get(sqlite3_stmt *statement, int column) {
    return sqlite3_column_double(statement, column);
} };

template <>
struct Column<int> {
static int Get(sqlite3_stmt *statement, int column) {
    return sqlite3_column_int(statement, column);
} };

template <>
struct Column<int64_t> {
static int64_t Get(sqlite3_stmt *statement, int column) {
    return sqlite3_column_int64(statement, column);
} };

template <>
struct Column<Beam> {
static Beam Get(sqlite3_stmt *statement, int column) {
    return Beam(sqlite3_column_blob(statement, column), sqlite3_column_bytes(statement, column));
} };

template <>
struct Column<std::vector<uint8_t>> {
static std::vector<uint8_t> Get(sqlite3_stmt *statement, int column) {
    const auto data(static_cast<const uint8_t *>(sqlite3_column_blob(statement, column)));
    return std::vector<uint8_t>(data, data + sqlite3_column_bytes(statement, column));
} };

template <>
struct Column<std::string> {
static std::string Get(sqlite3_stmt *statement, int column) {
    return std::string(reinterpret_cast<const char *>(sqlite3_column_text(statement, column)), sqlite3_column_bytes(statement, column));
} };

template <>
struct Column<std::u16string> {
static std::u16string Get(sqlite3_stmt *statement, int column) {
    return std::u16string(static_cast<const char16_t *>(sqlite3_column_text16(statement, column)), sqlite3_column_bytes16(statement, column) / sizeof(char16_t));
} };

template <typename Type_>
struct Column<std::optional<Type_>> {
static std::optional<Type_> Get(sqlite3_stmt *statement, int column) {
    if (sqlite3_column_type(statement, column) == SQLITE_NULL)
        return std::nullopt;
    return Column<Type_>::Get(statement, column);
} };

template <typename... Columns_, size_t... Indices_>
inline std::tuple<Columns_...> Row(sqlite3_stmt *statement, std::index_sequence<Indices_...>) {
    return std::make_tuple<Columns_...>(Column<Columns_>::Get(statement, Indices_)...);
}


inline bool Step(Database &database_, sqlite3_stmt *statement) {
    switch (orc_sqlstep(sqlite3_step(statement))) {
        case SQLITE_DONE:
            return false;
        case SQLITE_ROW:
            return true;
        default:
            orc_assert(false);
    }
}

template <typename... Columns_>
class Cursor_ final {
  private:
    Database &database_;
    sqlite3_stmt *statement_;

  public:
    Cursor_(Database &database) :
        database_(database),
        statement_(nullptr)
    {
    }

    Cursor_(Database &database, sqlite3_stmt *statement) :
        database_(database),
        statement_(statement)
    {
        operator ++();
    }

    Cursor_ &begin() {
        return *this;
    }

    Cursor_ end() {
        return database_;
    }

    Cursor_ &operator ++() {
        orc_assert(statement_ != nullptr);
        if (!Step(database_, statement_))
            statement_ = nullptr;
        return *this;
    }

    auto operator *() {
        return Row<Columns_...>(statement_, std::index_sequence_for<Columns_...>());
    }

    bool operator !=(const Cursor_ &rhs) noexcept {
        orc_insist(&database_ == &rhs.database_);
        return statement_ != rhs.statement_;
    }
};

template <typename... Columns_>
inline Cursor_<Columns_...> Cursor(Database &database, sqlite3_stmt *statement) {
    return Cursor_<Columns_...>(database, statement);
}

template <typename... Columns_>
inline std::optional<std::tuple<Columns_...>> Half(Database &database_, sqlite3_stmt *statement) {
    if (!Step(database_, statement))
        return std::nullopt;
    auto row(Row<Columns_...>(statement, std::index_sequence_for<Columns_...>()));
    orc_assert(!Step(database_, statement));
    return row;
}

template <typename... Columns_>
inline std::tuple<Columns_...> One(Database &database_, sqlite3_stmt *statement) {
    orc_assert(Step(database_, statement));
    auto row(Row<Columns_...>(statement, std::index_sequence_for<Columns_...>()));
    orc_assert(!Step(database_, statement));
    return row;
}

inline void None(Database &database_, sqlite3_stmt *statement) {
    orc_assert(!Step(database_, statement));
}

inline sqlite3_int64 Last(Database &database_, sqlite3_stmt *statement) {
    orc_assert(!Step(database_, statement));
    return sqlite3_last_insert_rowid(database_);
}

inline void Skip(Database &database_, sqlite3_stmt *statement) {
    orc_assert(Step(database_, statement));
    orc_assert(!Step(database_, statement));
}

}

#endif//ORCHID_DATABASE_HPP
