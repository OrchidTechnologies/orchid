#include "protect.hpp"


namespace orc {
    std::string tunIface;

    void setTunIface(const std::string &iface) {
        tunIface = iface;
    }

    std::string getTunIface() {
        return tunIface;
    }
}