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


#ifndef ORCHID_JSONRPC_HPP
#define ORCHID_JSONRPC_HPP

#include <string>

#include <boost/multiprecision/cpp_int.hpp>

#include <json/json.h>

#include "http.hpp"
#include "task.hpp"

namespace orc {

using boost::multiprecision::uint256_t;

class Argument final {
  private:
    Json::Value value_;

  public:
    Argument(uint256_t value) :
        value_(value.str())
    {
        std::cerr << value_ << std::endl;
    }

    Argument(const char *value) :
        value_(value)
    {
    }

    Argument(const std::string &value) :
        value_(value)
    {
    }

    Argument(std::initializer_list<Argument> args) {
        int index(0);
        for (auto arg(args.begin()); arg != args.end(); ++arg)
            value_[index++] = std::move(arg->value_);
    }

    Argument(std::map<std::string, Argument> args) {
        for (auto arg(args.begin()); arg != args.end(); ++arg)
            value_[std::move(arg->first)] = std::move(arg->second);
    }

    operator Json::Value &&() && {
        return std::move(value_);
    }
};

typedef std::map<std::string, Argument> Map;

class Endpoint final {
  private:
    const URI uri_;

  public:
    Endpoint(URI uri) :
        uri_(std::move(uri))
    {
    }

    task<std::string> operator ()(const std::string &method, Argument args);
};

}

#endif//ORCHID_JSONRPC_HPP
