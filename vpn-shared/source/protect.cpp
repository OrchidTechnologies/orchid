#include "protect.hpp"


namespace orc {
    // XXX: NOLINTNEXTLINE(cppcoreguidelines-avoid-non-const-global-variables)
    std::string tunIface;

    void setTunIface(const std::string &iface) {
        tunIface = iface;
    }

    std::string getTunIface() {
        return tunIface;
    }
}