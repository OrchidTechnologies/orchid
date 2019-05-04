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


#define _trace() \
    NSLog(@"_trace()[%s:%u]", __FILE__, __LINE__)

#include <NetworkExtension/NetworkExtension.h>

#include <OpenVPNAdapter/OpenVPNAdapter.h>
#include <OpenVPNAdapter/OpenVPNReachability.h>
#include <OpenVPNAdapter/OpenVPNAdapterPacketFlow.h>
#include <OpenVPNAdapter/OpenVPNConfiguration.h>
#include <OpenVPNAdapter/OpenVPNProperties.h>
#include <OpenVPNAdapter/OpenVPNCredentials.h>
#include <OpenVPNAdapter/OpenVPNReachabilityStatus.h>
#include <OpenVPNAdapter/OpenVPNError.h>
#include <OpenVPNAdapter/OpenVPNAdapterEvent.h>

#define orc_assert(code) do { \
    if (!(code)) [NSException raise:@"orc_assert" format:@"(%s)[%s:%u]", #code, __FILE__, __LINE__]; \
} while (false)

@interface NEPacketTunnelFlow ()<OpenVPNAdapterPacketFlow>
@end

@interface OrchidPacketTunnelProvider : NEPacketTunnelProvider<OpenVPNAdapterDelegate>

@property(nonatomic,strong) OpenVPNAdapter *adapter;
@property(nonatomic,strong) OpenVPNReachability *reachability;

@property(nonatomic,copy) void (^startHandler)(NSError * _Nullable);
@property(nonatomic,copy) void (^stopHandler)();

@end

@implementation OrchidPacketTunnelProvider

- (OpenVPNAdapter *) adapter {
    if (_adapter == nil) {
        _adapter = [[OpenVPNAdapter alloc] init];
        _adapter.delegate = self;
    }

    return _adapter;
}

- (OpenVPNReachability *) reachability {
    if (_reachability == nil) {
        _reachability = [[OpenVPNReachability alloc] init];
    }

    return _reachability;
}

- (void) handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData * _Nullable))handler {
}


- (void) startTunnelWithOptions:(NSDictionary<NSString *, NSObject *> *)options completionHandler:(void (^)(NSError * _Nullable))handler {
    NSError *error;

    NETunnelProviderProtocol *proto = (NETunnelProviderProtocol *) self.protocolConfiguration;
    orc_assert(proto != nil);

    NSDictionary<NSString *, id> *provider(proto.providerConfiguration);
    orc_assert(provider != nil);

    NSData *fileContent = provider[@"ovpn"];
    orc_assert(fileContent != nil);

    OpenVPNConfiguration *configuration([[OpenVPNConfiguration alloc] init]);
    configuration.fileContent = fileContent;
    configuration.disableClientCert = true;

    OpenVPNProperties *properties = [self.adapter applyConfiguration:configuration error:&error];
    if (error != nil)
        return handler(error);

    if (!properties.autologin) {
        OpenVPNCredentials *credentials = [[OpenVPNCredentials alloc] init];
        credentials.username = [NSString stringWithFormat:@"%@",[options objectForKey:@"username"]];
        credentials.password = [NSString stringWithFormat:@"%@",[options objectForKey:@"password"]];
        [self.adapter provideCredentials:credentials error:&error];
        if (error != nil)
            return handler(error);
    }

    [self.reachability startTrackingWithCallback:^(OpenVPNReachabilityStatus status) {
        if (status != OpenVPNReachabilityStatusNotReachable)
            [self.adapter reconnectAfterTimeInterval:5];
    }];

    [self.adapter connect];
    self.startHandler = handler;
}

- (void) stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))handler {
    if ([self.reachability isTracking])
        [self.reachability stopTracking];

    [self.adapter disconnect];
    self.stopHandler = handler;
}


- (void) openVPNAdapter:(OpenVPNAdapter *)adapter configureTunnelWithNetworkSettings:(NEPacketTunnelNetworkSettings *)networkSettings completionHandler:(void (^)(id<OpenVPNAdapterPacketFlow> _Nullable))handler {
    __weak __typeof(self) weak_self = self;
    [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
        if (error != nil)
            return handler(nil);
        return handler(weak_self.packetFlow);
    }];
}

- (void) openVPNAdapter:(OpenVPNAdapter *)adapter handleError:(NSError *)error {
    if (![error.userInfo[OpenVPNAdapterErrorFatalKey] boolValue])
        return;

    if ([self.reachability isTracking])
        [self.reachability stopTracking];

    if (auto handler = self.startHandler) {
        self.startHandler = nil;
        return handler(error);
    } else {
        [self cancelTunnelWithError:error];
    }
}

- (void) openVPNAdapter:(OpenVPNAdapter *)adapter handleEvent:(OpenVPNAdapterEvent)event message:(NSString *)message {
    switch (event) {
        case OpenVPNAdapterEventConnected:
            if (self.reasserting)
                self.reasserting = false;
            if (self.startHandler != nil)
                self.startHandler(nil);
            self.startHandler = nil;
        break;

        case OpenVPNAdapterEventDisconnected:
            if (self.reachability.isTracking)
                [self.reachability stopTracking];
            self.stopHandler();
            self.stopHandler = nil;
        break;

        case OpenVPNAdapterEventReconnecting:
            self.reasserting = true;
        break;

        default:
        break;
    }
}

- (void) openVPNAdapter:(OpenVPNAdapter *)adapter handleLogMessage:(NSString *)message {
    NSLog(@"OpenVPN: %@", message);
}

- (void) openVPNAdapterDidReceiveClockTick:(OpenVPNAdapter *)adapter {
}

@end
