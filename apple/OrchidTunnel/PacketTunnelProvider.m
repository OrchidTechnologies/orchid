  //
//  PacketTunnelProvider.m
//  OrchidTunnel
//
//  Created by Greg Hazel on 6/11/18.
//  Copyright © 2018 Example. All rights reserved.
//

#import "PacketTunnelProvider.h"
#include "orchid.h"


PacketTunnelProvider *packetTunnelProvider;

@implementation PacketTunnelProvider

+ (PacketTunnelProvider*)sharedProvider
{
    return packetTunnelProvider;
}

- (NSDictionary<NSString *,id>*)config
{
    return ((NETunnelProviderProtocol*)self.protocolConfiguration).providerConfiguration;
}

- (void)startTunnelWithOptions:(nullable NSDictionary<NSString *,NSObject *> *)options completionHandler:(void (^)(NSError * __nullable error))completionHandler
{
    NSLog(@"startTunnelWithOptions %@", options);
    dispatch_async(dispatch_get_main_queue(), ^{
        packetTunnelProvider = self;
        [super startTunnelWithOptions:options completionHandler:completionHandler];

        [self readPacketsFromTunnel];
        NEPacketTunnelNetworkSettings *settings = [NEPacketTunnelNetworkSettings.alloc initWithTunnelRemoteAddress:@"127.0.0.1"];
        settings.IPv4Settings = [NEIPv4Settings.alloc initWithAddresses:@[@"10.7.0.3"] subnetMasks:@[@"255.255.255.0"]];
        settings.IPv4Settings.includedRoutes = @[NEIPv4Route.defaultRoute];

        // TODO: IPv6
        //settings.IPv6Settings = [NEIPv6Settings.alloc initWith...

        settings.DNSSettings = [NEDNSSettings.alloc initWithServers:@[@"8.8.8.8", @"8.8.4.4"]];

        NSLog(@"setTunnelNetworkSettings %@", settings);
        [self setTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
            NSLog(@"setTunnelNetworkSettings error: %@", error);
            completionHandler(error);
            start_listener();
            [packetTunnelProvider readPacketsFromTunnel];
        }];
    });
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"stopTunnelWithReason %ld", (long)reason);
    [super stopTunnelWithReason:reason completionHandler:completionHandler];
    completionHandler();
    // kill the extension. is this a good idea?
    exit(0);
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
	// Add code here to handle the message.
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
	// Add code here to get ready to sleep.
	completionHandler();
}

- (void)wake {
	// Add code here to wake up.
}

- (void)readPacketsFromTunnel
{
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> * _Nonnull packets, NSArray<NSNumber *> * _Nonnull protocols) {
        NSData *outPackets[packets.count];
        NSNumber *outProtocols[protocols.count];
        size_t insert = 0;
        for (int i = 0; i < packets.count; i++) {
            NSData *packet = packets[i];
            NSNumber *protocol = protocols[i];
            if (!on_tunnel_packet((const uint8_t*)packet.bytes, packet.length)) {
                outPackets[insert] = packet;
                outProtocols[insert] = protocol;
                insert++;
            }
        }
        if (insert) {
            NSArray *wPackets = packets;
            NSArray *wProtocols = protocols;
            if (insert != packets.count) {
                wPackets = [NSArray arrayWithObjects:outPackets count:insert];
                wProtocols = [NSArray arrayWithObjects:outProtocols count:insert];
            }
            [self.packetFlow writePackets:wPackets withProtocols:wProtocols];
        }
        [self readPacketsFromTunnel];
    }];
}

void write_tunnel_packet(const uint8_t *packet, size_t length)
{
    if (length < sizeof(ip)) {
        return;
    }
    sa_family_t protocol = address_family((const ip*)packet);

    // HMM: this copies. instead, take ownership of packet and free when NSData is destroyed
    NSData *d = [NSData dataWithBytes:packet length:length];

    [packetTunnelProvider.packetFlow writePackets:@[d] withProtocols:@[@(protocol)]];
}

@end
