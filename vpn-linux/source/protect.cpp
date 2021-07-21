#include "fit.hpp"
#include "port.hpp"
#include "protect.hpp"
#include "log.hpp"

#include <netinet/in.h>
#include <string>
#include <iostream>
#include <optional>


namespace orc {

std::optional<std::string> default_gateway_outside_tun(const std::string &tun)
{
    char buf[1024];
    FILE *f = popen("route -n", "r");
    int lines = 0;
    while (feof(f) == 0 && fgets(buf, sizeof(buf), f) != nullptr) {
        if (lines >= 2) {
            std::istringstream ss(buf);
            // Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
            // 0.0.0.0         172.17.0.1      0.0.0.0         UG    0      0        0 eth0
            #define ORC_READ(field) \
                std::string field; \
                ss >> field;
            ORC_READ(dst)
            ORC_READ(gateway)
            ORC_READ(genmask)
            ORC_READ(flags)
            ORC_READ(metric)
            ORC_READ(ref)
            ORC_READ(use)
            ORC_READ(iface)
            // TODO: we should compare IP with destintion/mask for non-default routes
            if (iface != tun && dst == "0.0.0.0") {
                pclose(f);
                return iface;
            }
        }
        lines++;
    }
    pclose(f);
    return {};
}

bool vpn_protect(int s) {
    auto oiface = default_gateway_outside_tun(getTunIface());
    if (!oiface) {
        return false;
    }
    auto iface = *oiface;
    return setsockopt(s, SOL_SOCKET, SO_BINDTODEVICE, iface.c_str(), Fit(iface.length())) >= 0;
}

int Protect(int socket, int (*attach)(int, const sockaddr *, socklen_t), const sockaddr *address, socklen_t length) {

    bool is_local = false;
    if (address->sa_family == AF_INET) {
        const struct sockaddr_in *s = reinterpret_cast<const struct sockaddr_in *>(address);
        is_local = (Host(s->sin_addr) == Host_);
        if (!is_local && !vpn_protect(socket))
            return -1;
    }
    return attach(socket, address, length);
}
};
