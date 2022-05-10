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


// the order of these headers matters :/
#include <sys/sys_domain.h>
#include <sys/kern_control.h>
#include <net/if_utun.h>

#include <NetworkExtension/NetworkExtension.h>

#include "capture.hpp"
#include "family.hpp"
#include "local.hpp"
#include "port.hpp"
#include "sync.hpp"
#include "transport.hpp"

//if (!(code)) [NSException raise:@"orc_assert" format:@"(%s)[%s:%u]", #code, __FILE__, __LINE__];

using namespace orc;

#define ORC_CATCH(handler) \
catch (const std::exception &error) { \
    orc::Log() << error.what() << std::endl; \
    orc_insist(false); \
} catch(...) { \
    /* XXX: implement */ \
    orc_insist(false); \
}

#if 0
// XXX: this flags -Wunused-function as it isn't in a header file
static inline std::string cfs(NSData *data) {
    if (data != nil)
        return {static_cast<const char *>([data bytes]), [data length]};
    else return {};
}
#endif

static inline std::string cfs(NSString *data) {
    if (data != nil)
        return [data UTF8String];
    else return {};
}

static inline NSString *cfs(const std::string &data) {
    return [NSString stringWithUTF8String:data.c_str()];
}

@interface OrchidPacketTunnelProvider : NEPacketTunnelProvider {
    U<BufferSink<Capture>> capture_;
}

@end

@implementation OrchidPacketTunnelProvider

- (id) init {
    if ((self = [super init]) != nil) {
        Initialize();
    } return self;
}

- (void) startTunnelWithOptions:(NSDictionary<NSString *, NSObject *> *)options completionHandler:(void (^)(NSError *_Nullable))handler { try {
    auto protocol((NETunnelProviderProtocol *) self.protocolConfiguration);
    orc_assert(protocol != nil);

    auto config(cfs((NSString *) [options objectForKey:@"config"]));

    auto settings([NEPacketTunnelNetworkSettings.alloc initWithTunnelRemoteAddress:@"127.0.0.1"]);
    settings.MTU = @1100;

    settings.IPv4Settings = [NEIPv4Settings.alloc initWithAddresses:@[cfs(Host_.operator std::string())] subnetMasks:@[@"255.255.255.0"]];
    settings.IPv4Settings.includedRoutes = @[NEIPv4Route.defaultRoute];

    settings.DNSSettings = [NEDNSSettings.alloc initWithServers:@[cfs(Resolver_.operator std::string())]];

    [self setTunnelNetworkSettings:settings completionHandler:^(NSError *_Nullable error) { try {
        orc_assert_(error == nil, [[error localizedDescription] UTF8String]);

        auto file([]() {
            // Apple removed [self.packetFlow valueForKeyPath:@"socket.fileDescriptor"] in iOS 15
            // this technique is from https://blog.csdn.net/qq_26359763/article/details/118331747
            char name[IFNAMSIZ];
            socklen_t size;
            // XXX: I think there is a way to request the size of the file descriptor table
            for (int fd(0); fd != 1024; ++fd)
                if (getsockopt(fd, SYSPROTO_CONTROL, UTUN_OPT_IFNAME, name, &(size = sizeof(name))) == 0)
                    if (strncmp(name, "utun", 4) == 0)
                        return fd;
            orc_assert_(false, "could not find utun fd");
        }());

        // XXX: seriously consider if using Covered here is sane
        auto capture(std::make_unique<Covered<BufferSink<Capture>>>(Break<Local>(), Host_));
        try {
            auto &family(capture->Wire<BufferSink<Family>>());
            auto &sync(family.Wire<Sync<asio::generic::datagram_protocol::socket, SyncConnection>>(Context(), asio::generic::datagram_protocol(PF_SYSTEM, SYSPROTO_CONTROL), file));

            capture->Start(config);
            sync.Open();
            capture_ = std::move(capture);
        } catch (const std::exception &error) {
            orc::Log() << error.what() << std::endl;
            // XXX: this needs to not happen and the code below needs to be fixed
            orc_insist(false);
            std::string what(error.what());
            Spawn([capture = std::move(capture), handler, what = std::move(what)]() noexcept -> task<void> {
                co_await capture->Shut();
                // XXX: this clearly isn't right, but the orc_insist above is short circuiting
                handler(nil);
            }, __FUNCTION__);
        }
        handler(nil);
    } ORC_CATCH(handler) }];
} ORC_CATCH(handler) }

- (void) stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))handler {
    Spawn([capture = std::move(capture_), handler]() noexcept -> task<void> {
        co_await capture->Shut();
        handler();
    }, __FUNCTION__);
}

@end
