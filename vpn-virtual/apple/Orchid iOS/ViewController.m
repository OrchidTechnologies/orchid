//
//  ViewController.m
//  Orchid iOS
//
//  Created by Greg Hazel on 6/11/18.
//  Copyright © 2018 Example. All rights reserved.
//

#import "ViewController.h"
@import NetworkExtension;

#define kTunnelProviderBundle @"com.orchid.exampleios.Orchid-iOS.OrchidTunnel-iOS"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    dispatch_group_t removeGroup = dispatch_group_create();
    dispatch_group_enter(removeGroup);
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        NSLog(@"loadAllFromPreferencesWithCompletionHandler %@", error);
        for (NETunnelProviderManager *manager in managers) {
            dispatch_group_enter(removeGroup);
            [manager.connection stopVPNTunnel];
            [manager removeFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                NSLog(@"removeFromPreferencesWithCompletionHandler %@", error);
                // starting immediately seems to fail if it just deleted something, so wait a bit -- not sure what it's waiting for...
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    dispatch_group_leave(removeGroup);
                });
            }];
        }
        dispatch_group_leave(removeGroup);
    }];

    dispatch_group_notify(removeGroup, dispatch_get_main_queue(), ^{
        NETunnelProviderManager *manager = NETunnelProviderManager.new;
        [manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            NSLog(@"loadFromPreferencesWithCompletionHandler %@", error);
            NETunnelProviderProtocol *providerProtocol = NETunnelProviderProtocol.new;

            NSMutableDictionary *providerConfiguration = NSMutableDictionary.dictionary;
            providerProtocol.providerConfiguration = providerConfiguration;

            providerProtocol.providerBundleIdentifier = kTunnelProviderBundle;
            providerProtocol.serverAddress = @"Orchid";
            providerProtocol.username = @"";

            manager.protocolConfiguration = providerProtocol;
            manager.enabled = true;
            manager.localizedDescription = @"Orchid";

            [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                NSLog(@"saveToPreferencesWithCompletionHandler %@", error);
                [manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                    NSLog(@"loadFromPreferencesWithCompletionHandler %@", error);
                    self.title = manager.protocolConfiguration.serverAddress;
                    NSLog(@"manager.connection.status: %ld", (long)manager.connection.status);
                    NSError *e;
                    [manager.connection startVPNTunnelAndReturnError:&e];
                    NSLog(@"startVPNTunnelAndReturnError: %@", e);
                }];
            }];
        }];
    });
}


@end
