#include "port.hpp"
#include "protect.hpp"
#include "log.hpp"

#include <netinet/in.h>


namespace orc {

bool vpn_protect(int s) {
    // XXX: don't hard-code eth0
    return setsockopt(s, SOL_SOCKET, SO_BINDTODEVICE, "eth0", 4) >= 0;
}

int Protect(int socket, int (*attach)(int, const sockaddr *, socklen_t), const sockaddr *address, socklen_t length) {

    bool is_local = false;
    if (address->sa_family == AF_INET) {
        const struct sockaddr_in *s = reinterpret_cast<const struct sockaddr_in *>(address);
        is_local = (Host(s->sin_addr) == Host_);
    }
    if (!is_local && !vpn_protect(socket))
        return -1;
    return attach(socket, address, length);
}
};