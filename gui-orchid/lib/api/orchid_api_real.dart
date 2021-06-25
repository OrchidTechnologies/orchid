import 'dart:async';
import 'package:flutter/services.dart';
import 'package:orchid/api/monitoring/restart_manager.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'configuration/orchid_vpn_config/orchid_vpn_config.dart';
import 'monitoring/routing_status.dart';
import 'orchid_budget_api.dart';
import 'orchid_eth/v0/orchid_eth_v0.dart';
import 'orchid_log_api.dart';

class RealOrchidAPI implements OrchidAPI {
  static final RealOrchidAPI _singleton = RealOrchidAPI._internal();
  static const _platform = const MethodChannel("orchid.com/feedback");

  factory RealOrchidAPI() {
    return _singleton;
  }

  final vpnExtensionStatus = BehaviorSubject<OrchidVPNExtensionState>.seeded(
      OrchidVPNExtensionState.Invalid);

  /// The Orchid network connection state, which combines both the vpn extension
  /// status and the orchid network routing status.
  final vpnRoutingStatus = BehaviorSubject<OrchidVPNRoutingState>.seeded(
      OrchidVPNRoutingState.VPNNotConnected);

  final vpnPermissionStatus = BehaviorSubject<bool>();

  final circuitConfigurationChanged = BehaviorSubject<void>.seeded(null);

  RealOrchidAPI._internal() {
    // Update the overall orchid connection state when the vpn or orchid tunnel
    // connection state changes.
    _initVPNRoutingStatusListener();

    // Respond to native channel callbacks
    _initChannelListener();
  }

  /// The Flutter application uses this method to indicate to the native channel code
  /// that the UI has finished launching and all listeners have been established.
  Future<void> applicationReady() async {
    log("api: Application ready.");
    _platform.invokeMethod('ready');

    // Write the config file on startup
    await updateConfiguration();

    // Monitor user preferences and start or stop the VPN extension.
    await OrchidRestartManager().initVPNControlListener();
  }

  /// Respond to native channel callbacks
  void _initChannelListener() {
    _platform.setMethodCallHandler((MethodCall call) async {
      //log("status: Method call handler: $call");
      switch (call.method) {
        case 'connectionStatus':
          switch (call.arguments) {
            case 'Invalid':
              vpnExtensionStatus.add(OrchidVPNExtensionState.Invalid);
              break;
            case 'Disconnected':
              vpnExtensionStatus.add(OrchidVPNExtensionState.NotConnected);
              break;
            case 'Connecting':
              vpnExtensionStatus.add(OrchidVPNExtensionState.Connecting);
              break;
            case 'Connected':
              vpnExtensionStatus.add(OrchidVPNExtensionState.Connected);
              break;
            case 'Disconnecting':
              vpnExtensionStatus.add(OrchidVPNExtensionState.Disconnecting);
              break;
            case 'Reasserting':
              vpnExtensionStatus.add(OrchidVPNExtensionState.Connecting);
              break;
          }
          break;

        case 'providerStatus':
          //print("ProviderStatus called in API: ${call.arguments}");
          vpnPermissionStatus.add(call.arguments);
          break;

        /*
        case 'route':
          routeStatus.add(call.arguments
              .map((route) => OrchidNode(
                    ip: IPAddress(route),
                    location: Location(),
                  ))
              .toList());
          break;
           */
      }
    });
  }

  /// This listener weaves together changes in the vpn extension state and
  /// the Orchid tunnel routing connection state for the composite state.
  void _initVPNRoutingStatusListener() {
    Rx.combineLatest2(vpnExtensionStatus, OrchidRoutingStatus().connected,
        (OrchidVPNExtensionState vpnState, bool orchidConnected) {
      log("status: combine status: $vpnState, $orchidConnected");
      switch (vpnState) {
        case OrchidVPNExtensionState.Invalid:
        case OrchidVPNExtensionState.NotConnected:
          return OrchidVPNRoutingState.VPNNotConnected;
          break;
        case OrchidVPNExtensionState.Connecting:
          return OrchidVPNRoutingState.VPNConnecting;
          break;
        case OrchidVPNExtensionState.Connected:
          // This differentiates the vpn running state from the orchid routing state
          return (orchidConnected
              ? OrchidVPNRoutingState.OrchidConnected
              : OrchidVPNRoutingState.VPNConnected);
          break;
        case OrchidVPNExtensionState.Disconnecting:
          return OrchidVPNRoutingState.VPNDisconnecting;
          break;
      }
    }).listen((OrchidVPNRoutingState state) async {
      applyRoutingStatus(state);
    });
  }

  static applyRoutingStatus(OrchidVPNRoutingState state) async {
    var vpnRoutingStatus = OrchidAPI().vpnRoutingStatus;

    // Determine if the change in connection state is relevant to routing.
    // (as opposed to e.g. a change in state for traffic monitoring)
    var routingEnabled = await UserPreferences().routingEnabled.get();
    switch (state) {
      case OrchidVPNRoutingState.VPNNotConnected:
        vpnRoutingStatus.add(state);
        break;
      case OrchidVPNRoutingState.VPNConnecting:
      case OrchidVPNRoutingState.VPNConnected:
      case OrchidVPNRoutingState.OrchidConnected:
        if (routingEnabled) {
          vpnRoutingStatus.add(state);
        }
        break;
      case OrchidVPNRoutingState.VPNDisconnecting:
        // If we are disconnecting and routing is disabled it is ambiguous
        // whether the disconnect is due to shutting down routing or monitoring.
        // Disambiguate using the current state of the routing status.
        var residualRoutingStatus =
            vpnRoutingStatus.value != OrchidVPNRoutingState.VPNNotConnected;
        if (!routingEnabled && residualRoutingStatus) {
          vpnRoutingStatus.add(state);
        }
        break;
    }
  }

  /// Get the logging API.
  @override
  OrchidLogAPI logger() {
    return OrchidLogAPI.defaultLogAPI;
  }

  @override
  Future<bool> requestVPNPermission() {
    return _platform.invokeMethod('install');
  }

  Future<void> revokeVPNPermission() async {
    throw Exception("Unimplemented");
  }

  @override
  Future<void> setVPNExtensionEnabled(bool enabled) async {
    if (enabled) {
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
  OrchidBudgetAPI budget() {
    return OrchidBudgetAPI();
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
    log("api: combined config = {$combinedConfig}");

    // todo: return a bool from the native side?
    String result = await _platform
        .invokeMethod('set_config', <String, dynamic>{'text': combinedConfig});
    return result == 'true';
  }

  // Generate the portion of the VPN config managed by the GUI.  Managed config
  // precedes user config in the tunnel, supporting overrides.
  // The desired format is (JavaScript, not JSON) e.g.:
  static Future<String> generateManagedConfig() async {
    // Circuit configuration
    var managedConfig = (await UserPreferences().routingEnabled.get())
        ? await OrchidVPNConfig.generateConfig()
        : "";

    // Inject the default (main net Ethereum) RPC provider
    managedConfig +=
        '\nrpc = "${OrchidEthereumV0.defaultEthereumProviderUrl}";';

    // Inject the status socket name
    managedConfig += '\ncontrol = "${OrchidRoutingStatus.socketName}";';

    // To disable monitoring set 'logdb' to an empty string.
    if (!await UserPreferences().monitoringEnabled.get()) {
      managedConfig += '\nlogdb="";';
    }

    return managedConfig;
  }

  // Generate the combined user config and generated config
  static Future<String> generateCombinedConfig(String userConfig) async {
    // Append the generated config before saving.
    String generatedConfig;
    try {
      generatedConfig = await generateManagedConfig();
    } catch (err, stack) {
      OrchidAPI().logger().write("Error rendering config: $err\n$stack");
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

  void dispose() {
    vpnExtensionStatus.close();
    circuitConfigurationChanged.close();
    vpnRoutingStatus.close();
    vpnPermissionStatus.close();
  }
}
