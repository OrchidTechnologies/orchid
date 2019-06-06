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


#include <sys/sys_domain.h>
#include <sys/kern_control.h>

#include <NetworkExtension/NetworkExtension.h>

#include "connection.hpp"
#include "transport.hpp"

//if (!(code)) [NSException raise:@"orc_assert" format:@"(%s)[%s:%u]", #code, __FILE__, __LINE__];

using namespace orc;

#define ORC_CATCH(handler) catch(...) { \
    /* XXX: implement */ \
    orc_insist(false); \
}

static std::string cfs(NSData *data) {
    if (data != nil)
        return {static_cast<const char *>([data bytes]), [data length]};
    else return {};
}

static std::string cfs(NSString *data) {
    if (data != nil)
        return [data UTF8String];
    else return {};
}

@interface OrchidPacketTunnelProvider : NEPacketTunnelProvider {
    U<Sink<Capture>> capture_;
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

    auto provider(protocol.providerConfiguration);
    orc_assert(provider != nil);

    auto ovpnfile(cfs((NSData *) provider[@"ovpnfile"]));
    auto username(cfs((NSString *) [options objectForKey:@"username"]));
    auto password(cfs((NSString *) [options objectForKey:@"password"]));

    auto settings([NEPacketTunnelNetworkSettings.alloc initWithTunnelRemoteAddress:@"127.0.0.1"]);

    settings.IPv4Settings = [NEIPv4Settings.alloc initWithAddresses:@[@"10.7.0.3"] subnetMasks:@[@"255.255.255.0"]];
    settings.IPv4Settings.includedRoutes = @[NEIPv4Route.defaultRoute];

    settings.DNSSettings = [NEDNSSettings.alloc initWithServers:@[@"8.8.8.8", @"8.8.4.4"]];

    [self setTunnelNetworkSettings:settings completionHandler:^(NSError *_Nullable error) { try {
        orc_assert_(error == nil, [[error localizedDescription] UTF8String]);

        auto flow(self.packetFlow);
        orc_assert(flow != nil);
        auto value((NSNumber *) [flow valueForKeyPath:@"socket.fileDescriptor"]);
        orc_assert(value != nil);
        int file([value intValue]);
        orc_assert(file != -1);

        auto capture(std::make_unique<Sink<Capture>>("10.7.0.3"));
        auto connection(capture->Wire<Connection<asio::generic::datagram_protocol::socket>>(asio::generic::datagram_protocol(PF_SYSTEM, SYSPROTO_CONTROL), file));
        connection->Start();

        Spawn([
            capture = std::move(capture),
            ovpnfile = std::move(ovpnfile),
            username = std::move(username),
            password = std::move(password),
            handler = handler,
        self]() mutable -> task<void> { try {
            co_await Schedule();
            co_await capture->Start(std::move(ovpnfile), std::move(username), std::move(password));
            capture_ = std::move(capture);
            handler(nil);
        } ORC_CATCH(handler) });
    } ORC_CATCH(handler) }];
} ORC_CATCH(handler) }

- (void) stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))handler {
    // XXX: implement
    orc_insist(false);
    capture_.reset();
    handler();
}

@end
