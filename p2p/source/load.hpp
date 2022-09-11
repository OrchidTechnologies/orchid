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

namespace orc {

void Create(const std::string &path);
void Delete(const std::string &file);

bool Exists(const std::string &path);
uint64_t Modified(const std::string &file);

std::string Load(const std::string &file);
void Save(const std::string &file, const std::string &data);

}

#endif//ORCHID_LOAD_HPP
