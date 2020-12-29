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


#include "sync.hpp"
#include "tunnel.hpp"
#include "port.hpp"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tchar.h>
#include <cfgmgr32.h>
#include <ndisguid.h>
#include <objbase.h>
#include <devioctl.h>

extern "C" {
#include "tap-windows.h"
}

#include <netinet/in.h>

namespace orc {

std::string guid_to_name(const char *guid)
{
    HKEY network_connections_key;
    // XXX: NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    LONG status = RegOpenKeyExA(HKEY_LOCAL_MACHINE, NETWORK_CONNECTIONS_KEY, 0, KEY_READ, &network_connections_key);

    if (status != ERROR_SUCCESS) {
        Log() << "Error opening registry key: " << NETWORK_CONNECTIONS_KEY << std::endl;
        return nullptr;
    }

    for (int i = 0; ; i++) {
        char enum_name[256];
        DWORD len = sizeof(enum_name);
        status = RegEnumKeyExA(network_connections_key, i, enum_name, &len,
                               nullptr, nullptr, nullptr, nullptr);
        if (status == ERROR_NO_MORE_ITEMS) {
            break;
        }
        if (status != ERROR_SUCCESS) {
            Log() << "Error enumerating registry subkeys of key: " << NETWORK_CONNECTIONS_KEY << std::endl;
            break;
        }

        auto connection_string = std::string(NETWORK_CONNECTIONS_KEY) + "\\" + enum_name + "\\Connection";

        HKEY connection_key;
        // XXX: NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
        status = RegOpenKeyExA(HKEY_LOCAL_MACHINE, connection_string.c_str(), 0, KEY_READ, &connection_key);

        if (status != ERROR_SUCCESS) {
            //Log() << "Error opening registry key: " << connection_string << std::endl;
            continue;
        }

        WCHAR name_data[256];
        DWORD name_type;
        len = sizeof(name_data);
        status = RegQueryValueExW(connection_key, L"Name", nullptr, &name_type, reinterpret_cast<LPBYTE>(name_data), &len);

        if (status != ERROR_SUCCESS || name_type != REG_SZ) {
            Log() << "Error opening registry key: " << NETWORK_CONNECTIONS_KEY << "\\" << connection_string << "\\Name" << std::endl;
        } else if (strcmp(enum_name, guid) == 0) {
            char name[1024];
            wcstombs(name, name_data, sizeof(name));
            RegCloseKey(connection_key);
            RegCloseKey(network_connections_key);
            return name;
        }
        RegCloseKey(connection_key);
    }

    RegCloseKey(network_connections_key);
    return nullptr;
}

void Tunnel(BufferSunk &sunk, const std::string &device, const std::function<void (const std::string &)> &code) {

    std::string actual_name;
    // XXX: NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    HANDLE h = INVALID_HANDLE_VALUE;

    HKEY adapter_key;
    // XXX: NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    LONG status = RegOpenKeyExA(HKEY_LOCAL_MACHINE, ADAPTER_KEY, 0, KEY_READ, &adapter_key);

    if (status != ERROR_SUCCESS) {
        Log() << "Error opening registry key: " << ADAPTER_KEY << std::endl;
    }

    for (int i = 0; ;i++) {
        char enum_name[256];
        DWORD len = sizeof(enum_name);
        status = RegEnumKeyExA(adapter_key, i, enum_name, &len, nullptr, nullptr, nullptr, nullptr);
        if (status == ERROR_NO_MORE_ITEMS) {
            break;
        }
        if (status != ERROR_SUCCESS) {
            Log() << "Error enumerating registry subkeys of key: " << ADAPTER_KEY << std::endl;
            break;
        }

        auto unit_string = std::string(ADAPTER_KEY) + "\\" + std::string(enum_name);

        HKEY unit_key;
        // XXX: NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
        status = RegOpenKeyExA(HKEY_LOCAL_MACHINE, unit_string.c_str(), 0, KEY_READ, &unit_key);

        if (status != ERROR_SUCCESS) {
            Log() << "Error opening registry key: " << unit_string << std::endl;
            continue;
        }

        DWORD data_type;
        char component_id[256];
        len = sizeof(component_id);
        status = RegQueryValueExA(unit_key, "ComponentId", nullptr, &data_type, reinterpret_cast<LPBYTE>(component_id), &len);

        if (status != ERROR_SUCCESS || data_type != REG_SZ) {
            Log() << "Error opening registry key: " << unit_string << "\\ComponentId" << std::endl;
            continue;
        }

        char net_cfg_instance_id[256];
        len = sizeof(net_cfg_instance_id);
        status = RegQueryValueExA(unit_key, "NetCfgInstanceId", nullptr, &data_type, reinterpret_cast<LPBYTE>(net_cfg_instance_id), &len);

        RegCloseKey(unit_key);

        if (status != ERROR_SUCCESS || data_type != REG_SZ) {
            continue;
        }
        if (strcasecmp(component_id, "tap0901") != 0 &&
            strcasecmp(component_id, "root\\tap0901") != 0) {
            continue;
        }

        auto path = std::string(USERMODEDEVICEDIR) + std::string(net_cfg_instance_id) + std::string(TAP_WIN_SUFFIX);
        h = CreateFileA(path.c_str(),
                        GENERIC_READ | GENERIC_WRITE,
                        0,
                        nullptr,
                        OPEN_EXISTING,
                        FILE_ATTRIBUTE_SYSTEM | FILE_FLAG_OVERLAPPED,
                        nullptr);
        // XXX: NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
        if (h == INVALID_HANDLE_VALUE) {
            continue;
        }
        BOOL status = TRUE;
        if (DeviceIoControl(h, TAP_WIN_IOCTL_SET_MEDIA_STATUS,
                            &status, sizeof(status),
                            &status, sizeof(status), &len, nullptr) == 0) {
            Log() << "WARNING: The TAP-Windows driver rejected a TAP_WIN_IOCTL_SET_MEDIA_STATUS DeviceIoControl call." << std::endl;
        }

        in_addr_t local = htonl(Host_.operator uint32_t());
        in_addr_t remote_netmask = inet_addr("255.255.255.0");
        in_addr_t ep[] {local, local & remote_netmask, remote_netmask};

        if (DeviceIoControl(h, TAP_WIN_IOCTL_CONFIG_TUN,
                            ep, sizeof(ep),
                            ep, sizeof(ep), &len, nullptr) == 0) {
            Log() << "WARNING: The TAP-Windows driver rejected a TAP_WIN_IOCTL_CONFIG_TUN DeviceIoControl call." << std::endl;
        }

        actual_name = guid_to_name(net_cfg_instance_id);
        break;
    }
    RegCloseKey(adapter_key);

    // XXX: NOLINTNEXTLINE (cppcoreguidelines-pro-type-vararg)
    auto &sync(sunk.Wire<SyncFile<asio::windows::stream_handle>>(Context(), h));

    code("\"" + actual_name + "\"");

    sync.Open();
}

}
