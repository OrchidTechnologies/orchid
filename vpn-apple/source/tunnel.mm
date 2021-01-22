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


#include <sys/sys_domain.h>
#include <sys/kern_control.h>

#include <NetworkExtension/NetworkExtension.h>

#include "capture.hpp"
#include "family.hpp"
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

    auto local(Host_);

    auto settings([NEPacketTunnelNetworkSettings.alloc initWithTunnelRemoteAddress:@"127.0.0.1"]);
    settings.MTU = @1100;

    settings.IPv4Settings = [NEIPv4Settings.alloc initWithAddresses:@[[NSString stringWithUTF8String:local.operator std::string().c_str()]] subnetMasks:@[@"255.255.255.0"]];
    settings.IPv4Settings.includedRoutes = @[NEIPv4Route.defaultRoute];

    settings.DNSSettings = [NEDNSSettings.alloc initWithServers:@[@"1.0.0.1"]];

    [self setTunnelNetworkSettings:settings completionHandler:^(NSError *_Nullable error) { try {
        orc_assert_(error == nil, [[error localizedDescription] UTF8String]);

        auto flow(self.packetFlow);
        orc_assert(flow != nil);
        auto value((NSNumber *) [flow valueForKeyPath:@"socket.fileDescriptor"]);
        orc_assert(value != nil);
        int file([value intValue]);
        orc_assert(file != -1);

        // XXX: seriously consider if using Covered here is sane
        auto capture(std::make_unique<Covered<BufferSink<Capture>>>(local));
        try {
            auto &family(capture->Wire<BufferSink<Family>>());
            auto &sync(family.Wire<SyncConnection<asio::generic::datagram_protocol::socket>>(Context(), asio::generic::datagram_protocol(PF_SYSTEM, SYSPROTO_CONTROL), file));

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
