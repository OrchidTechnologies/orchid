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


#include <Flutter/Flutter.h>
#include <UIKit/UIKit.h>
#include <NetworkExtension/NetworkExtension.h>

#include "trace.hpp"


static NSString * const username_ = @ ORCHID_USERNAME;
static NSString * const password_ = @ ORCHID_PASSWORD;


@interface GeneratedPluginRegistrant : NSObject

+ (void) registerWithRegistry:(NSObject<FlutterPluginRegistry> *)registry;

@end

@implementation GeneratedPluginRegistrant

+ (void) registerWithRegistry:(NSObject<FlutterPluginRegistry> *)registry {
}

@end


@interface AppDelegate : FlutterAppDelegate

@property(strong,nonatomic) NETunnelProviderManager *providerManager;

@end

@interface AppDelegate () {
    NSString *status_;
    FlutterMethodChannel *feedback_;
}

@end

@implementation AppDelegate

- (void) setVPN:(NSString *)status {
    status_ = status;
    NSLog(@"NEVPNStatus%@", status);
    [feedback_ invokeMethod:@"VPN" arguments:status];
}

- (void) onVpnState:(NEVPNStatus)status {
    switch (status) {
        case NEVPNStatusInvalid:
            [self setVPN:@"Invalid"];
            break;
        case NEVPNStatusDisconnected:
            [self setVPN:@"Disconnected"];
            break;
        case NEVPNStatusConnecting:
            [self setVPN:@"Connecting"];
            break;
        case NEVPNStatusConnected:
            [self setVPN:@"Connected"];
            break;
        case NEVPNStatusDisconnecting:
            [self setVPN:@"Disconnecting"];
            break;
        case NEVPNStatusReasserting:
            [self setVPN:@"Reasserting"];
            break;
        default:
            break;
    }
}

- (void) onVpnStateChange:(NSNotification *)notification {
    [self onVpnState:self.providerManager.connection.status];
}

- (void) initProvider {
    NETunnelProviderProtocol *protocol([[NETunnelProviderProtocol alloc] init]);

    NSURL *url([[NSBundle mainBundle] URLForResource:@"PureVPN" withExtension:@"ovpn"]);
    NSData *data([[NSData alloc] initWithContentsOfURL:url]);

    protocol.providerConfiguration = @{@"ovpn": data};
    protocol.providerBundleIdentifier = @ ORCHID_DOMAIN "." ORCHID_NAME ".VPN";
    protocol.serverAddress = @"mac.saurik.com";
    //protocol.serverAddress = @"ukl2-ovpn-tcp.pointtoserver.com";
    protocol.disconnectOnSleep = NO;

    [self.providerManager setEnabled:YES];
    [self.providerManager setProtocolConfiguration:protocol];
    self.providerManager.localizedDescription = @ ORCHID_NAME;
    [self.providerManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
        if (error)
            NSLog(@"Save error: %@", error);
        else {
            NSLog(@"add success");
            [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                NSLog(@"loadFromPreferences!");
            }];
        }
    }];

    [self onVpnState:self.providerManager.connection.status];
}


- (void) connection {
    [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil)
            return;

        [self.providerManager.connection startVPNTunnelWithOptions:@{
            @"username": username_,
            @"password": password_,
        } andReturnError:&error];

        if (error != nil)
            NSLog(@"Start error: %@", error.localizedDescription);

        NSLog(@"Connection established!");
    }];
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    [GeneratedPluginRegistrant registerWithRegistry:self];

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    self.window.backgroundColor = [UIColor whiteColor];

    FlutterViewController *flutter([FlutterViewController new]);
    self.window.rootViewController = flutter;

    feedback_ = [FlutterMethodChannel methodChannelWithName:@"orchid.com/feedback" binaryMessenger:flutter];

    __weak typeof(self) weakSelf = self;
    [feedback_ setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        if (false) {
        } else if ([@"connect" isEqualToString:call.method]) {
            [weakSelf connection];
        } else if ([@"reroute" isEqualToString:call.method]) {
        }
    }];

    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (error != nil)
            return;
        self.providerManager = managers.firstObject?managers.firstObject:[NETunnelProviderManager new];
        [self onVpnState:self.providerManager.connection.status];
        [self initProvider];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVpnStateChange:) name:NEVPNStatusDidChangeNotification object:nil];

    return [super application:application didFinishLaunchingWithOptions:options];
}

- (void) applicationWillResignActive:(UIApplication *)application {
}


- (void) applicationDidEnterBackground:(UIApplication *)application {
}


- (void) applicationWillEnterForeground:(UIApplication *)application {
}


- (void) applicationDidBecomeActive:(UIApplication *)application {
}


- (void) applicationWillTerminate:(UIApplication *)application {
}

@end


int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
