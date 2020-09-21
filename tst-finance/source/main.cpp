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


#include <sstream>

#include <boost/iostreams/filtering_streambuf.hpp>
#include <boost/iostreams/copy.hpp>
#include <boost/iostreams/filter/gzip.hpp>

#include <jwt/jwt.hpp>

#include "baton.hpp"
#include "endpoint.hpp"
#include "load.hpp"
#include "local.hpp"
#include "sleep.hpp"
#include "task.hpp"
#include "ticket.hpp"
#include "transport.hpp"

namespace orc {

std::string Bearer(const std::string &iss, const std::string &kid) {
    jwt::jwt_object object{
        jwt::params::algorithm("ES256"),
        jwt::params::secret(Load("AuthKey_" + kid + ".p8")),
        jwt::params::headers({{"kid", kid}}),
        jwt::params::payload({{"aud", "appstoreconnect-v1"}}),
    };

    object.add_claim("iss", iss);
    object.add_claim("exp", time(NULL) + 60);

    return object.signature();
}

std::string Deflate(const std::string &data) {
    namespace bio = boost::iostreams;

    bio::filtering_streambuf<bio::input> buffer;
    buffer.push(bio::gzip_decompressor());

    std::stringstream input(data);
    buffer.push(input);

    std::stringstream output;
    bio::copy(buffer, output);

    return output.str();
}

task<void> Main(int argc, const char *const argv[]) {
    Initialize();

    orc_assert(argc == 3);
    const std::string iss(argv[1]);
    const std::string kid(argv[2]);

    const auto origin(Break<Local>());

    std::cout << Deflate((co_await origin->Fetch("GET", {"https", "api.appstoreconnect.apple.com", "443", "/v1/salesReports?filter[frequency]=DAILY&filter[reportSubType]=SUMMARY&filter[reportType]=SALES&filter[vendorNumber]=88451190&filter[version]=1_0&filter[reportDate]=2020-09-15"}, {
        {"accept", "application/a-gzip"},
        {"authorization", "Bearer " + Bearer(iss, kid)},
    }, {})).ok()) << std::flush;

    _exit(0);
}

}

int main(int argc, const char *const argv[]) { try {
    orc::Wait(orc::Main(argc, argv));
    return 0;
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    return 1;
} }
