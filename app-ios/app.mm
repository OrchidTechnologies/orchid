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

static NSString * const username_ = @ ORCHID_USERNAME;
static NSString * const password_ = @ ORCHID_PASSWORD;


@interface GeneratedPluginRegistrant : NSObject

+ (void) registerWithRegistry:(NSObject<FlutterPluginRegistry> *)registry;

@end


@interface AppDelegate : FlutterAppDelegate

@property(strong,nonatomic) NETunnelProviderManager *providerManager;

@end

@interface AppDelegate () {
    FlutterMethodChannel *feedback_;
    
    // Connection status
    NSString *connectionStatus_;
    
    // VPN Provider installed status
    NSNumber *providerStatus_;
}

@end

@implementation AppDelegate

#pragma mark - VPN State

- (void) onVpnStateChange:(NSNotification *)notification {
    [self onVpnState:self.providerManager.connection.status];
    [self updateProviderStatus];
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

// Publish the VPN connection status to the app.
- (void) setVPN:(NSString *)status {
    if (connectionStatus_ != nil && [connectionStatus_ isEqualToString:status]) { return; }
    connectionStatus_ = status;
    NSLog(@"NEVPNStatus change%@", status);
    [feedback_ invokeMethod:@"connectionStatus" arguments:status];
}

#pragma mark - VPN Provider State

// Note: This does *not_ seem to fire if the user adds or removes the vpn config in settings, so
// Note: I'm not sure under what circumstances it is called.
- (void) onConfigurationChange:(NSNotification *)notification {
    NSLog(@"Provider state changed.");
    [self updateProviderStatus];
}

// Get the initialization state of the tunnel provider and publish it to the app.
- (void) updateProviderStatus {
    [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        // Is the provider enabled?
        if (!self.providerManager.enabled) {
            NSLog(@"Provider enabled: %d", self.providerManager.enabled);
            [self setProviderState: false];
            return;
        }
        // Is it a tunnel provider?
        NEVPNProtocol *providerConfig = self.providerManager.protocolConfiguration;
        if (![providerConfig isKindOfClass:[NETunnelProviderProtocol class]]) {
            NSLog(@"Provider protocol is not a tunnel protocol");
            [self setProviderState: false];
            return;
        }
        // Is it our tunnel provider?
        NETunnelProviderProtocol *tunnelConfig = (NETunnelProviderProtocol *)providerConfig;
        if (![tunnelConfig.providerBundleIdentifier hasPrefix:@ORCHID_DOMAIN]) {
            NSLog(@"Provider bundle id: %@", tunnelConfig.providerBundleIdentifier);
            [self setProviderState: false];
            return;
        }
        // Check for the correct version here?
        // ...
        [self setProviderState: true];
    }];
}

// Publish the provider initialization state to the app.
- (void) setProviderState: (bool)installed {
    if (providerStatus_ != nil && [providerStatus_ boolValue] == installed) { return; }
    providerStatus_ = [NSNumber numberWithBool: installed];
    NSLog(@"VPN Provider Status %d", installed);
    [feedback_ invokeMethod:@"providerStatus" arguments: @(installed)];
}

#pragma mark - App Initialization

- (void) initProvider: (FlutterResult)result {
    NETunnelProviderProtocol *protocol([[NETunnelProviderProtocol alloc] init]);

    NSURL *url([[NSBundle mainBundle] URLForResource:@"PureVPN" withExtension:@"ovpn"]);
    NSData *data([[NSData alloc] initWithContentsOfURL:url]);

    protocol.providerConfiguration = @{@"ovpnfile": data};
    protocol.providerBundleIdentifier = @ ORCHID_DOMAIN "." ORCHID_NAME ".VPN";
    protocol.serverAddress = @"mac.saurik.com";
    //protocol.serverAddress = @"ukl2-ovpn-tcp.pointtoserver.com";
    protocol.disconnectOnSleep = NO;

    [self.providerManager setEnabled:YES];
    [self.providerManager setProtocolConfiguration:protocol];
    self.providerManager.localizedDescription = @ ORCHID_NAME;
    [self.providerManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Save error: %@", error);
            result([NSNumber numberWithBool: false]);
        } else {
            NSLog(@"add success");
            [self updateProviderStatus];
            result([NSNumber numberWithBool: true]);
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

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    self.window.backgroundColor = [UIColor whiteColor];

    FlutterViewController *flutter([FlutterViewController new]);
    self.window.rootViewController = flutter;

    // Flutter plugins use [UIApplication sharedApplication].delegate.window.rootViewController to get the FlutterViewController
    [GeneratedPluginRegistrant registerWithRegistry:self];

    feedback_ = [FlutterMethodChannel methodChannelWithName:@"orchid.com/feedback" binaryMessenger:flutter];

    __weak typeof(self) weakSelf = self;
    [feedback_ setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        if (false) {
        } else if ([@"connect" isEqualToString:call.method]) {
            [weakSelf connection];
        } else if ([@"disconnect" isEqualToString:call.method]) {
            [weakSelf.providerManager.connection stopVPNTunnel];
        } else if ([@"reroute" isEqualToString:call.method]) {
        } else if ([@"install" isEqualToString:call.method]) {
            [weakSelf initProvider: result];
        } else if ([@"group_path" isEqualToString:call.method]) {
            [weakSelf groupPath: result];
        }
    }];

    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (error != nil)
            return;
        self.providerManager = managers.firstObject?managers.firstObject:[NETunnelProviderManager new];
        [self onVpnState:self.providerManager.connection.status];
        [self updateProviderStatus];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVpnStateChange:) name:NEVPNStatusDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConfigurationChange:) name:NEVPNConfigurationChangeNotification object:nil];

    return [super application:application didFinishLaunchingWithOptions:options];
}

// Get the shared group container path
- (void) groupPath: (FlutterResult)result {
    NSString *group = @("group." ORCHID_DOMAIN "." ORCHID_NAME);
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier: group];
    result(groupURL.path);
}

- (void) applicationWillResignActive:(UIApplication *)application {
}


- (void) applicationDidEnterBackground:(UIApplication *)application {
}


- (void) applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"Orchid entered foreground.");
    [self updateProviderStatus];
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
