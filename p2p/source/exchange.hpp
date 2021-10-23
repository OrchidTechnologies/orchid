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


#ifndef ORCHID_EXCHANGE_HPP
#define ORCHID_EXCHANGE_HPP

#include <cppcoro/async_generator.hpp>

#include <boost/date_time/posix_time/time_parsers.hpp>

#include "base.hpp"
#include "base64.hpp"
#include "notation.hpp"
#include "time.hpp"

namespace orc {

class Exchange {
  private:
    const S<Base> base_;

    const std::string key_;
    const std::string passphrase_;
    const Beam secret_;

  public:
    Exchange(S<Base> base) :
        base_(std::move(base))
    {
    }

    Exchange(S<Base> base, std::string key, std::string passphrase, Beam secret) :
        base_(std::move(base)),
        key_(std::move(key)),
        passphrase_(std::move(passphrase)),
        secret_(std::move(secret))
    {
    }

    task<Response> operator ()(const std::string &method, const std::string &path, const std::string &body) const {
        const auto timestamp(std::to_string(Timestamp()));
        const auto signature(ToBase64(Auth<Hash2>(secret_, Tie(timestamp, method, path, body))));

        co_return co_await base_->Fetch(method, {{"https", "api.pro.coinbase.com", "443"}, path}, {
            {"Content-Type", "application/json"},
            {"CB-ACCESS-KEY", key_},
            {"CB-ACCESS-SIGN", signature},
            {"CB-ACCESS-TIMESTAMP", timestamp},
            {"CB-ACCESS-PASSPHRASE", passphrase_}
        }, body);
    }

    task<Object> call(const std::string &method, const std::string &path, const std::string &body = {}) const {
        co_return Parse((co_await operator ()(method, path, body)).ok()).as_object();
    }

    task<Any> kill(const std::string &path, const std::string &body = {}) const {
        co_return Parse((co_await operator ()("DELETE", path, body)).ok());
    }

    cppcoro::async_generator<Object> list(std::string method, std::map<std::string, std::string> args) const {
        for (;;) {
            const auto path([&]() {
                std::ostringstream path;
                path << '/' << method;

                bool ampersand(false);
                for (const auto &arg : args) {
                    if (ampersand)
                        path << '&';
                    else {
                        path << '?';
                        ampersand = true;
                    }

                    path << arg.first << '=' << arg.second;
                }

                return path.str();
            }());

            auto response(co_await operator()("GET", path, {}));
            orc_assert_(response.result() == http::status::ok, response.body());

            auto body(Parse(response.body()));
            for (auto &value : body.as_array())
                co_yield std::move(value.as_object());

            const auto after(response.find("CB-AFTER"));
            if (after == response.end())
                break;
            args["after"] = Str(after->value());
        }
    }
};

}

#endif//ORCHID_EXCHANGE_HPP
