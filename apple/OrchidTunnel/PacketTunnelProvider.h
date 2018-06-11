//
//  PacketTunnelProvider.h
//  OrchidTunnel
//
//  Created by Greg Hazel on 6/11/18.
//  Copyright © 2018 Example. All rights reserved.
//

@import NetworkExtension;

@interface PacketTunnelProvider : NEPacketTunnelProvider

+ (PacketTunnelProvider*)sharedProvider;

@end
