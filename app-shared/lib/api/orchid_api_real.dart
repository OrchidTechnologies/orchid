import 'dart:async';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/orchid_vpn_config.dart';
import 'package:orchid/api/pricing.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/ip_address.dart';
import 'package:orchid/util/location.dart';
import 'package:rxdart/rxdart.dart';
import 'orchid_budget_api.dart';
import 'orchid_log_api.dart';

class RealOrchidAPI implements OrchidAPI {
  static final RealOrchidAPI _singleton = RealOrchidAPI._internal();
  static const _platform = const MethodChannel("orchid.com/feedback");

  factory RealOrchidAPI() {
    return _singleton;
  }

  RealOrchidAPI._internal() {
    _platform.setMethodCallHandler((MethodCall call) async {
      //print("Method call handler: $call");
      switch (call.method) {
        case 'connectionStatus':
          switch (call.arguments) {
            case 'Invalid':
              connectionStatus.add(OrchidConnectionState.Invalid);
              break;
            case 'Disconnected':
              connectionStatus.add(OrchidConnectionState.NotConnected);
              break;
            case 'Connecting':
              connectionStatus.add(OrchidConnectionState.Connecting);
              break;
            case 'Connected':
              connectionStatus.add(OrchidConnectionState.Connected);
              break;
            case 'Disconnecting':
              connectionStatus.add(OrchidConnectionState.Disconnecting);
              break;
            case 'Reasserting':
              connectionStatus.add(OrchidConnectionState.Connecting);
              break;
          }
          break;

        case 'providerStatus':
          //print("ProviderStatus called in API: ${call.arguments}");
          vpnPermissionStatus.add(call.arguments);
          break;

        case 'route':
          routeStatus.add(call.arguments
              .map((route) => OrchidNode(
                    ip: IPAddress(route),
                    location: Location(),
                  ))
              .toList());
          break;
      }
    });
  }

  final networkConnectivity = BehaviorSubject<NetworkConnectivityType>.seeded(
      NetworkConnectivityType.Unknown);
  final connectionStatus = BehaviorSubject<OrchidConnectionState>.seeded(
      OrchidConnectionState.Invalid);
  final syncStatus = BehaviorSubject<OrchidSyncStatus>();
  final routeStatus = BehaviorSubject<OrchidRoute>();
  final vpnPermissionStatus = BehaviorSubject<bool>();
  final circuitConfigurationChanged = BehaviorSubject<void>.seeded(null);

  /// Transient, in-memory log implementation.
  OrchidLogAPI _logAPI = MemoryOrchidLogAPI();

  /// The Flutter application uses this method to indicate to the native channel code
  /// that the UI has finished launching and all listeners have been established.
  Future<void> applicationReady() async {
    budget().applicationReady();
    _platform.invokeMethod('ready');

    // Write the config file on startup
    await updateConfiguration();

    // Set the initial VPN state from user preferences
    setConnected(await UserPreferences().getDesiredVPNState());
  }

  /// Get the logging API.
  @override
  OrchidLogAPI logger() {
    return _logAPI;
  }

  @override
  Future<bool> requestVPNPermission() {
    return _platform.invokeMethod('install');
  }

  Future<void> revokeVPNPermission() async {
    // TODO:
  }

  @override
  Future<bool> setWallet(OrchidWallet wallet) {
    return Future<bool>.value(false);
  }

  @override
  Future<void> clearWallet() async {}

  @override
  Future<OrchidWalletPublic> getWallet() {
    return Future<OrchidWalletPublic>.value(null);
  }

  @override
  Future<bool> setExitVPNConfig(VPNConfig vpnConfig) {
    return Future<bool>.value(false);
  }

  @override
  Future<VPNConfigPublic> getExitVPNConfig() {
    return Future<VPNConfigPublic>.value(null);
  }

  @override
  Future<void> setConnected(bool connect) async {
    if (connect) {
      await updateConfiguration();
      await _platform.invokeMethod('connect');
    } else {
      await _platform.invokeMethod('disconnect');
    }
  }

  @override
  Future<void> reroute() async {
    await _platform.invokeMethod('reroute');
  }

  @override
  Future<Map<String, String>> getDeveloperSettings() async {
    return Map();
  }

  @override
  void setDeveloperSetting({String name, String value}) {
    // TODO:
  }

  @override
  OrchidBudgetAPI budget() {
    return OrchidBudgetAPI();
  }

  @override
  OrchidPricingAPI pricing() {
    return OrchidPricingAPI();
  }

  Future<String> groupContainerPath() async {
    return _platform.invokeMethod('group_path');
  }

  Future<String> versionString() async {
    return _platform.invokeMethod('version');
  }

  /// Get the User visible Orchid Configuration file contents
  Future<String> getConfiguration() async {
    // return _platform.invokeMethod('get_config');
    // Return only the user visible portion of the config.
    return await UserPreferences().getUserConfig();
  }

  /// Set the User visible Orchid Configuration file contents
  /// and publish it to the VPN.
  Future<bool> setConfiguration(String userConfig) async {
    String combinedConfig = await generateCombinedConfig(userConfig);

    // todo: return a bool from the native side?
    String result = await _platform
        .invokeMethod('set_config', <String, dynamic>{'text': combinedConfig});
    return result == "true";
  }

  // Generate the portion of the VPN config managed by the GUI.
  // The desired format is (JavaScript, not JSON) e.g.:
  static Future<String> generateManagedConfig() async {
    var hopsListConfig = await OrchidVPNConfig.generateHopsConfig();
    //  Currently the hops list is the only managed config.
    return hopsListConfig;
  }

  // Generate the combined user config and generated config
  static Future<String> generateCombinedConfig(String userConfig) async {
    // Append the generated config before saving.
    String generatedConfig;
    try {
      generatedConfig = await generateManagedConfig();
    } catch (err) {
      OrchidAPI().logger().write("Error rendering config: $err");
      generatedConfig = " ";
    }

    // Concatenate the user config and generated config
    var combinedConfig = generatedConfig + "\n" + (userConfig ?? "");
    return combinedConfig;
  }

  /// Publish the latest configuration to the VPN.
  Future<bool> updateConfiguration() async {
    return setConfiguration(await UserPreferences().getUserConfig());
  }
}
