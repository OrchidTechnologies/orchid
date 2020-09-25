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


#define bind system_bind
#define connect system_connect

#include_next <sys/socket.h>

#undef bind
#undef connect

#define ORC_IMPORT

#ifdef __linux__
#define ORC_SYMBOL ""
#else
#define ORC_SYMBOL "_"
#endif

#ifdef __cplusplus
extern "C"
#endif
int bind(int socket, const struct sockaddr *address, socklen_t length) __asm__(ORC_SYMBOL "orchid_bind");

#ifdef __cplusplus
extern "C"
#endif
int connect(int socket, const struct sockaddr *address, socklen_t length) __asm__(ORC_SYMBOL "orchid_connect");
