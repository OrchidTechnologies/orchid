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


#include <Foundation/Foundation.h>

#include <sys/codesign.h>

#include "directory.hpp"
#include "syscall.hpp"

namespace orc {

static std::string Blob(unsigned int ops) {
    struct {
        uint32_t magic;
        uint32_t size;
    } orc_packed header;

    if (orc_syscall(csops(0, ops, &header, sizeof(header)), ERANGE) == 0)
        return std::string();

    size_t size(ntohl(header.size));
    char data[size];
    memset(data, 0xff, sizeof(data));
    orc_syscall(csops(0, ops, data, sizeof(data)));
    return std::string(data + sizeof(header), size - sizeof(header));
}

std::string Group() {
    auto blob(Blob(CS_OPS_ENTITLEMENTS_BLOB));
    NSDictionary *plist([NSPropertyListSerialization propertyListWithData:[NSData dataWithBytesNoCopy:&blob[0] length:blob.size() freeWhenDone:NO] options:NSPropertyListImmutable format:NULL error:NULL]);
    NSString *group([[plist objectForKey:@"com.apple.security.application-groups"] objectAtIndex:0]);
    return [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:group].path.UTF8String;
}

}
