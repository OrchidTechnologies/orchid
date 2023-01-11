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


#ifndef ORCHID_LOAD_HPP
#define ORCHID_LOAD_HPP

#include <string>

#include <boost/filesystem/string_file.hpp>

#include "syscall.hpp"

namespace orc {

inline void Create(const std::string &path) {
#ifdef _WIN32
    orc_syscall(mkdir(path.c_str()), ERROR_ALREADY_EXISTS);
#else
    orc_syscall(mkdir(path.c_str(), 0755));
#endif
}

inline bool Exists(const std::string &path) {
    return orc_syscall(access(path.c_str(), F_OK), ENOENT) == 0;
}

// XXX: boost's string_file has been deprecated for some reason :(

inline std::string Load(const std::string &file) { orc_block({
    std::string data;
    boost::filesystem::load_string_file(file, data);
    return data;
}, "loading from " << file); }

inline void Save(const std::string &file, const std::string &data) { orc_block({
    boost::filesystem::save_string_file(file, data);
}, "saving to " << file); }

}

#endif//ORCHID_LOAD_HPP
