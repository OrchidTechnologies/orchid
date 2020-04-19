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


@interface GeneratedPluginRegistrant : NSObject

+ (void) registerWithRegistry:(NSObject<FlutterPluginRegistry> *)registry;

@end


@interface AppDelegate : FlutterAppDelegate

@property(strong,nonatomic) NETunnelProviderManager *providerManager;

@end

@interface AppDelegate () {
    FlutterMethodChannel *feedback_;
    
    // The application's desired VPN state: true for on, false for off.
    // This is populated from user preferences at launch.
    NSNumber *desiredVPNState_;
}

@end

@implementation AppDelegate

#pragma mark - VPN State

- (void) onVpnStateChange:(NSNotification *)notification {
    [self onVpnState:self.providerManager.connection.status];
    [self updateProviderStatus];
    [self setDesiredConnectionStateIfNeeded];
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
    NSLog(@"NEVPNStatus change %@", status);
    [feedback_ invokeMethod:@"connectionStatus" arguments:status];
}

#pragma mark - VPN Provider State

// Note: This does *not* seem to fire if the user adds or removes the vpn config in settings, so
// Note: I'm not sure under what circumstances it is called.
- (void) onConfigurationChange:(NSNotification *)notification {
    NSLog(@"Provider state changed.");
    [self updateProviderStatus];
}

// Get the initialization state of the tunnel provider and publish it to the app.
- (void) updateProviderStatus {
    [self providerStatus: ^(bool result) {
        [self setProviderState: result];
    }];
}

// Get the connection state of the provider manager and publish it to the app.
- (void) updateConnectionStatus {
    if (self.providerManager != nil) {
      [self onVpnState:self.providerManager.connection.status];
    } else {
      [self onVpnState: NEVPNStatusInvalid];
    }
}

// Get the initialization state of the tunnel provider
- (void) providerStatus: (void(^)(bool)) completionHandler {
    [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        // Is the provider enabled?
        if (!self.providerManager.enabled) {
            NSLog(@"Provider enabled: %d", self.providerManager.enabled);
            completionHandler(false);
            return;
        }
        // Is it a tunnel provider?
        NEVPNProtocol *providerConfig = self.providerManager.protocolConfiguration;
        if (![providerConfig isKindOfClass:[NETunnelProviderProtocol class]]) {
            NSLog(@"Provider protocol is not a tunnel protocol");
            completionHandler(false);
            return;
        }
        // Is it our tunnel provider?
        NETunnelProviderProtocol *tunnelConfig = (NETunnelProviderProtocol *)providerConfig;
        if (![tunnelConfig.providerBundleIdentifier hasPrefix:@ORCHID_DOMAIN]) {
            NSLog(@"Provider bundle id: %@", tunnelConfig.providerBundleIdentifier);
            completionHandler(false);
            return;
        }
        // Check for the correct version here?
        // ...
        completionHandler(true);
    }];
}

// Publish the provider initialization state to the app.
- (void) setProviderState: (bool)installed {
    NSLog(@"VPN Provider Status %d", installed);
    [feedback_ invokeMethod:@"providerStatus" arguments: @(installed)];
}

#pragma mark - VPN Initialization

- (void) initProvider: (FlutterResult)result {
    NETunnelProviderProtocol *protocol([[NETunnelProviderProtocol alloc] init]);

    protocol.providerConfiguration = @{};
    protocol.providerBundleIdentifier = @ ORCHID_DOMAIN "." ORCHID_NAME ".VPN";
    protocol.serverAddress = @"Orchid";
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

// Start the tunnel
- (void) startVPN {
    desiredVPNState_ = [NSNumber numberWithBool: true];
    [self.providerManager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Start load preferences error: %@", error.localizedDescription);
            return;
        }

        NSURL *url = [self getConfigURL];
        [self.providerManager.connection startVPNTunnelWithOptions:@{
            @"config": [url path],
        } andReturnError:&error];

        if (error != nil)
            NSLog(@"Start error: %@", error.localizedDescription);

        NSLog(@"Connection established!");
    }];
}

// Start the tunnel
- (void) stopVPN {
    desiredVPNState_ = [NSNumber numberWithBool: false];
    [self.providerManager.connection stopVPNTunnel];
}

// Check the current connection state and desired state,
// starting or stopping the VPN as required.
-(void) setDesiredConnectionStateIfNeeded {
    NEVPNStatus status = self.providerManager.connection.status;
    switch (status) {
        case NEVPNStatusInvalid:
        case NEVPNStatusConnecting:
        case NEVPNStatusDisconnecting:
        case NEVPNStatusReasserting:
            // Do nothing on intermediate states
            break;
        case NEVPNStatusConnected:
            if (desiredVPNState_ != nil && [desiredVPNState_ boolValue] == false) {
                NSLog(@"Reasserting desired connection state: Off");
                [self stopVPN];
            }
            break;
        case NEVPNStatusDisconnected:
            if (desiredVPNState_ != nil && [desiredVPNState_ boolValue] == true) {
                NSLog(@"Reasserting desired connection state: On");
                [self startVPN];
            }
            break;
        default:
            break;
    }
    
}

#pragma mark - Lifecycle Methods

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    self.window.backgroundColor = [UIColor whiteColor];

    FlutterViewController *flutter([FlutterViewController new]);
    self.window.rootViewController = flutter;

    // Flutter plugins use [UIApplication sharedApplication].delegate.window.rootViewController to get the FlutterViewController
    [GeneratedPluginRegistrant registerWithRegistry:self];

    feedback_ = [FlutterMethodChannel methodChannelWithName:@"orchid.com/feedback" binaryMessenger:flutter.binaryMessenger];

    __weak typeof(self) weakSelf = self;
    [feedback_ setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
        if (false) {
        } else if ([@"ready" isEqualToString:call.method]) {
            [weakSelf applicationReady];
        } else if ([@"connect" isEqualToString:call.method]) {
            [weakSelf startVPN];
        } else if ([@"disconnect" isEqualToString:call.method]) {
            [weakSelf stopVPN];
        } else if ([@"reroute" isEqualToString:call.method]) {
        } else if ([@"install" isEqualToString:call.method]) {
            [weakSelf initProvider: result];
        } else if ([@"group_path" isEqualToString:call.method]) {
            [weakSelf groupPath: result];
        } else if ([@"version" isEqualToString:call.method]) {
            const auto info([[NSBundle mainBundle] infoDictionary]);
            result([NSString stringWithFormat:@"%@ (%@)", [info objectForKey:@"CFBundleShortVersionString"], [info objectForKey:@"CFBundleVersion"]]);
        } else if ([@"get_config" isEqualToString:call.method]) {
            [weakSelf getConfig: result];
        } else if ([@"set_config" isEqualToString:call.method]) {
            NSString *text = call.arguments[@"text"];
            [weakSelf setConfig: text result: result];
        }
    }];

    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error loading NE tunnel prefs.");
            return;
        }
        self.providerManager = managers.firstObject?managers.firstObject:[NETunnelProviderManager new];
        [self onVpnState:self.providerManager.connection.status];
        [self updateProviderStatus];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onVpnStateChange:) name:NEVPNStatusDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onConfigurationChange:) name:NEVPNConfigurationChangeNotification object:nil];

    return [super application:application didFinishLaunchingWithOptions:options];
}

// Get the shared group container path
- (NSURL *) groupURL {
    NSString *group = @("group." ORCHID_DOMAIN "." ORCHID_NAME);
    NSURL *groupURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier: group];
    return groupURL;
}

// Get the shared group container path
- (void) groupPath: (FlutterResult)result {
    NSURL *groupURL = [self groupURL];
    result(groupURL.path);
}

- (NSURL *) getConfigURL {
    NSURL *groupURL = [self groupURL];
    return [groupURL URLByAppendingPathComponent: @"config.cfg"];
}

- (NSString *) getConfig {
    NSURL *url = [self getConfigURL];
    NSError *error; // todo
    NSString *content = [NSString stringWithContentsOfFile:[url path] encoding:NSASCIIStringEncoding error:&error];
    if (error!=nil) {
      NSLog(@"Get config error: %@", error);
      return nil;
    }
    return content;
}
- (void) getConfig: (FlutterResult)result {
    result([self getConfig]);
}

- (bool) setConfig: (NSString *)text {
    NSURL *url = [self getConfigURL];
    //NSLog(@"Write config {%@} to file: %@", text, [url path]);
    NSError *error; // todo
    [text writeToFile:[url path] atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error!=nil) {
      NSLog(@"Save config error: %@", error);
    }
    return error == nil;
}
- (void) setConfig: (NSString *)text result: (FlutterResult)result {
    result([self setConfig: text] ? @"true" : @"false"); // todo
}

- (void) applicationWillResignActive:(UIApplication *)application {
}


- (void) applicationDidEnterBackground:(UIApplication *)application {
}


- (void) applicationWillEnterForeground:(UIApplication *)application {
    [self setDesiredConnectionStateIfNeeded];
}


- (void) applicationDidBecomeActive:(UIApplication *)application {
}

// Called when the flutter application startup is complete and listeners are registered.
- (void) applicationReady {
    NSLog(@"Application ready");
    [self updateProviderStatus];
    [self updateConnectionStatus];
}

- (void) applicationWillTerminate:(UIApplication *)application {
}

@end


int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
