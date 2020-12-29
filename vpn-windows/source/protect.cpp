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


#include <winsock2.h>
#include <iphlpapi.h>

#include "log.hpp"
#include "port.hpp"
#include "protect.hpp"

namespace orc {

DWORD getTunIface() {
    DWORD dwSize = sizeof(IP_ADAPTER_ADDRESSES) + 1024;
    auto addresses = std::make_unique<uint8_t[]>(dwSize);
    auto pAddresses = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(addresses.get());

    for (;;) {
        DWORD r = GetAdaptersAddresses(AF_INET,
                                       GAA_FLAG_SKIP_ANYCAST|GAA_FLAG_SKIP_MULTICAST|
                                       GAA_FLAG_SKIP_DNS_SERVER|GAA_FLAG_SKIP_FRIENDLY_NAME,
                                       nullptr, pAddresses, &dwSize);
        if (r == ERROR_BUFFER_OVERFLOW) {
            addresses = std::make_unique<uint8_t[]>(dwSize);
            pAddresses = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(addresses.get());
            continue;
        } else if (r != NO_ERROR) {
            TCHAR lpMsgBuf[1024];
            if (FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                             nullptr, r, MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US),
                             lpMsgBuf, sizeof(lpMsgBuf), nullptr)) {
                Log() << "GetAdaptersAddresses error: " << lpMsgBuf << std::endl;
            }
        }
        break;
    }

    for (PIP_ADAPTER_ADDRESSES curAddress = pAddresses; curAddress != nullptr; curAddress = curAddress->Next) {
        if (curAddress->OperStatus != IfOperStatusUp && curAddress->OperStatus != IfOperStatusDormant) {
            continue;
        }
        if (curAddress->FirstUnicastAddress == nullptr) {
            continue;
        }
        sockaddr_in *sin = reinterpret_cast<sockaddr_in*>(curAddress->FirstUnicastAddress->Address.lpSockaddr);
        if (sin->sin_addr.s_addr == htonl(Host_.operator uint32_t())) {
            return curAddress->IfIndex;
        }
    }
    return -1;
}

#define SUBNET_EQ(a, mask, b) ((a & mask) == (b & mask))

std::pair<DWORD, DWORD> default_gateway_outside_tun(u_long dest)
{
    DWORD dwSize = sizeof(MIB_IPFORWARDTABLE) + 1024;
    auto ipForwardTable = std::make_unique<uint8_t[]>(dwSize);
    auto pIpForwardTable = reinterpret_cast<PMIB_IPFORWARDTABLE>(ipForwardTable.get());

    for (;;) {
        DWORD r = GetIpForwardTable(pIpForwardTable, &dwSize, 0);
        if (r == ERROR_INSUFFICIENT_BUFFER) {
            ipForwardTable = std::make_unique<uint8_t[]>(dwSize);
            pIpForwardTable = reinterpret_cast<PMIB_IPFORWARDTABLE>(ipForwardTable.get());
            continue;
        } else if (r != NO_ERROR) {
            TCHAR lpMsgBuf[1024];
            if (FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                             nullptr, r, MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US),
                             lpMsgBuf, sizeof(lpMsgBuf), nullptr)) {
                Log() << "GetIpForwardTable error: " << lpMsgBuf << std::endl;
            }
            return std::make_pair(-1, 0);
        }
        break;
    }

    DWORD tunIndex = getTunIface();
    DWORD prefix = 0;
    DWORD index = -1;
    DWORD metric = ULONG_MAX;
    DWORD nextHop = 0;
    for (DWORD i = 0; i < pIpForwardTable->dwNumEntries; i++) {
        PMIB_IPFORWARDROW row = &pIpForwardTable->table[i];
        if (row->dwForwardType == MIB_IPROUTE_TYPE_INVALID) {
            continue;
        }
        if (row->dwForwardIfIndex == tunIndex) {
            continue;
        }
        if (!SUBNET_EQ(row->dwForwardDest, row->dwForwardMask, dest)) {
            continue;
        }
        DWORD forwardPrefix = dest & row->dwForwardMask;
        if (forwardPrefix > prefix || (forwardPrefix == prefix && row->dwForwardMetric1 < metric)) {
            prefix = forwardPrefix;
            index = row->dwForwardIfIndex;
            metric = row->dwForwardMetric1;
            nextHop = row->dwForwardNextHop;
        }
    }
    return std::make_pair(index, nextHop);
}

std::unique_ptr<sockaddr_storage> get_addr_by_index(DWORD index)
{
    DWORD dwSize = sizeof(IP_ADAPTER_ADDRESSES) + 1024;
    auto addresses = std::make_unique<uint8_t[]>(dwSize);
    auto pAddresses = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(addresses.get());

    for (;;) {
        DWORD r = GetAdaptersAddresses(AF_INET,
                                       GAA_FLAG_SKIP_ANYCAST|GAA_FLAG_SKIP_MULTICAST|
                                       GAA_FLAG_SKIP_DNS_SERVER|GAA_FLAG_SKIP_FRIENDLY_NAME,
                                       nullptr, pAddresses, &dwSize);
        if (r == ERROR_BUFFER_OVERFLOW) {
            addresses = std::make_unique<uint8_t[]>(dwSize);
            pAddresses = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(addresses.get());
            continue;
        } else if (r != NO_ERROR) {
            return nullptr;
        }
        break;
    }

    for (PIP_ADAPTER_ADDRESSES curAddress = pAddresses; curAddress != nullptr; curAddress = curAddress->Next) {
        if (curAddress->IfIndex != index) {
            continue;
        }
        if (curAddress->OperStatus != IfOperStatusUp && curAddress->OperStatus != IfOperStatusDormant) {
            continue;
        }
        if (curAddress->FirstUnicastAddress == nullptr) {
            continue;
        }
        auto a = curAddress->FirstUnicastAddress->Address;
        auto s = std::make_unique<sockaddr_storage>();
        memcpy(s.get(), a.lpSockaddr, a.iSockaddrLength);
        return s;
    }
    return nullptr;
}

int Protect(SOCKET socket, int (*attach)(SOCKET, const sockaddr *, socklen_t), const sockaddr *address, socklen_t length) {
    if (address->sa_family != AF_INET) {
        return attach(socket, address, length);
    }
    const sockaddr_in *sin = reinterpret_cast<const sockaddr_in *>(address);

    auto [index, gateway] = default_gateway_outside_tun(sin->sin_addr.s_addr);

    DWORD dwSize = sizeof(IP_ADAPTER_ADDRESSES) + 1024;
    auto addresses = std::make_unique<uint8_t[]>(dwSize);
    auto pAddresses = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(addresses.get());

    for (;;) {
        DWORD r = GetAdaptersAddresses(AF_INET,
                                       GAA_FLAG_SKIP_ANYCAST|GAA_FLAG_SKIP_MULTICAST|
                                       GAA_FLAG_SKIP_DNS_SERVER|GAA_FLAG_SKIP_FRIENDLY_NAME,
                                       nullptr, pAddresses, &dwSize);
        if (r == ERROR_BUFFER_OVERFLOW) {
            addresses = std::make_unique<uint8_t[]>(dwSize);
            pAddresses = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(addresses.get());
            continue;
        } else if (r != NO_ERROR) {
            TCHAR lpMsgBuf[1024];
            if (FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                                     nullptr, r, MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US),
                                     lpMsgBuf, sizeof(lpMsgBuf), nullptr)) {
                Log() << "GetAdaptersAddresses error: " << lpMsgBuf << std::endl;
            }
            return attach(socket, address, length);
        }
        break;
    }

    for (PIP_ADAPTER_ADDRESSES curAddress = pAddresses; curAddress != nullptr; curAddress = curAddress->Next) {
        if (curAddress->IfIndex != index) {
            continue;
        }
        if (curAddress->OperStatus != IfOperStatusUp && curAddress->OperStatus != IfOperStatusDormant) {
            continue;
        }
        if (curAddress->FirstUnicastAddress == nullptr) {
            continue;
        }
        bool done = false;
        for (auto ua = curAddress->FirstUnicastAddress; ua != nullptr; ua = ua->Next) {
            auto a = ua->Address;
            sockaddr_in *sin = reinterpret_cast<sockaddr_in*>(a.lpSockaddr);
            ULONG mask;
            ConvertLengthToIpv4Mask(ua->OnLinkPrefixLength, &mask);
            if (SUBNET_EQ(sin->sin_addr.s_addr, mask, gateway)) {
                auto r = bind(socket, a.lpSockaddr, a.iSockaddrLength);
                if (r < 0) {
                    Log() << "bind failed:" << WSAGetLastError() << std::endl;
                }
                done = true;
                break;
            }
        }
        if (done) {
            break;
        }
    }
    return attach(socket, address, length);
}

}
