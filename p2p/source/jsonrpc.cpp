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


#include <json/json.h>

#include "error.hpp"
#include "http.hpp"
#include "jsonrpc.hpp"
#include "trace.hpp"

namespace orc {

task<std::string> Endpoint::operator ()(const std::string &method, const std::vector<std::string> &args) {
    Json::Value root;
    root["jsonrpc"] = "2.0";
    root["method"] = method;
    root["id"] = "";

    Json::Value params;
    for (size_t i(0); i != args.size(); ++i)
        params[Json::ArrayIndex(i)] = args[i];
    root["params"] = std::move(params);

    Json::FastWriter writer;
    auto body(co_await Request("POST", uri_, {{"content-type", "application/json"}}, writer.write(root)));
    Log() << "[[ " << body << " ]]" << std::endl;

    Json::Value result;
    Json::Reader reader;
    orc_assert(reader.parse(std::move(body), result, false));

    orc_assert(result["jsonrpc"] == "2.0");
    orc_assert(result["id"] == "");
    co_return result["result"].asString();
}


task<std::string> Endpoint::eth_call(const std::string& to, const std::string& data)
{
    std::cout << "():0" << std::endl;
    Json::Value root;
    root["jsonrpc"] = "2.0";
    root["method"] = "eth_call";
    root["id"] = "";

    std::cout << "():1" << std::endl;
    Json::Value obj;
    obj["to"]   = to;
    obj["data"] = data;
    Json::Value params;
    params[Json::ArrayIndex(0)] = obj;
    root["params"] = std::move(params);

    std::cout << "():2" << std::endl;
    Json::FastWriter writer;
    auto root_val = writer.write(root);
    std::cout << root_val << std::endl;
    auto body(co_await Request("POST", uri_, {{"content-type", "application/json"}}, root_val));
    Log() << "[[ " << body << " ]]" << std::endl;

    std::cout << "():3" << std::endl;
    Json::Value result;
    Json::Reader reader;
    orc_assert(reader.parse(std::move(body), result, false));

    std::cout << "():4 \n";
    orc_assert(result["jsonrpc"] == "2.0");
    orc_assert(result["id"] == "");
    co_return result["result"].asString();
}



}
