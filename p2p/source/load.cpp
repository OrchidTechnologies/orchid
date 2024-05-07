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


#ifdef _WIN32
#include <windows.h>
#include <winsock2.h>
#endif

#include <fstream>

#include <sys/stat.h>
#include <sys/types.h>

#include "fit.hpp"
#include "syscall.hpp"

namespace orc {

void Create(const std::string &path) {
#ifdef _WIN32
    orc_syscall(mkdir(path.c_str()), ERROR_ALREADY_EXISTS);
#else
    orc_syscall(mkdir(path.c_str(), 0755), EEXIST);
#endif
}

void Delete(const std::string &path) {
    orc_syscall(unlink(path.c_str()));
}

bool Exists(const std::string &path) {
    return orc_syscall(access(path.c_str(), F_OK), ENOENT) == 0;
}

uint64_t Modified(const std::string &path) {
    struct stat info{};
    orc_syscall(stat(path.c_str(), &info));
    return info.st_mtime;
}

std::string Load(const std::string &path) { orc_block({
    std::ifstream file;
    file.exceptions(std::ifstream::failbit | std::ifstream::badbit);
    file.open(path, std::ios::binary);
    const auto begin(file.tellg());
    file.seekg(0, std::ios::end);
    std::string data;
    data.resize(Fit(Pos(file.tellg() - begin)));
    file.seekg(0, std::ios::beg);
    file.read(data.data(), data.size());
    return data;
}, "loading from " << path); }

void Save(const std::string &path, const std::string &data) { orc_block({
    std::ofstream file;
    file.exceptions(std::ofstream::failbit | std::ofstream::badbit);
    file.open(path, std::ios::binary);
    file.write(data.data(), data.size());
}, "saving to " << path); }

}
