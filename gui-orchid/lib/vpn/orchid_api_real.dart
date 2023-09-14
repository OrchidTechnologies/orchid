import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/vpn/monitoring/analysis_db.dart';
import 'package:orchid/vpn/monitoring/restart_manager.dart';
import 'package:orchid/vpn/monitoring/routing_status.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:rxdart/rxdart.dart';
import 'orchid_vpn_config/orchid_vpn_config_generate.dart';

class RealOrchidAPI implements OrchidAPI {
  static final RealOrchidAPI _singleton = RealOrchidAPI._internal();
  static const _platform = const MethodChannel('orchid.com/feedback');

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
    await _platform.invokeMethod('ready');

    // Write the config file on startup
    await publishConfiguration();

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
          // Trigger a refresh of the app level status which should now report down.
          OrchidRoutingStatus().invalidate();
          return OrchidVPNRoutingState.VPNNotConnected;
        case OrchidVPNExtensionState.Connecting:
          return OrchidVPNRoutingState.VPNConnecting;
        case OrchidVPNExtensionState.Connected:
          // This differentiates the vpn running state from the app level orchid routing state
          return (orchidConnected
              ? OrchidVPNRoutingState.OrchidConnected
              : OrchidVPNRoutingState.VPNConnected);
        case OrchidVPNExtensionState.Disconnecting:
          return OrchidVPNRoutingState.VPNDisconnecting;
      }
    }).listen((OrchidVPNRoutingState state) async {
      applyRoutingStatus(state);
    });
  }

  // Determine if the change in connection state is relevant to routing.
  // (as opposed to e.g. a change in state for traffic monitoring)
  static applyRoutingStatus(OrchidVPNRoutingState state) async {
    var publishStatus = OrchidAPI().vpnRoutingStatus;
    var routingEnabled = UserPreferencesVPN().routingEnabled.get()!;

    switch (state) {
      case OrchidVPNRoutingState.VPNNotConnected:
        publishStatus.add(state);
        break;
      case OrchidVPNRoutingState.VPNConnecting:
      case OrchidVPNRoutingState.VPNConnected:
      case OrchidVPNRoutingState.OrchidConnected:
        if (routingEnabled) {
          publishStatus.add(state);
        }
        break;
      case OrchidVPNRoutingState.VPNDisconnecting:
        // If we are disconnecting and routing is disabled it is ambiguous
        // whether the disconnect is due to shutting down routing or monitoring.
        // Disambiguate using the current state of the routing status.
        var residualRoutingStatus =
            publishStatus.value != OrchidVPNRoutingState.VPNNotConnected;
        if (!routingEnabled && residualRoutingStatus) {
          publishStatus.add(state);
        }
        break;
    }
  }

  @override
  Future<bool> requestVPNPermission() async {
    return await _platform.invokeMethod('install');
  }

  Future<void> revokeVPNPermission() async {
    throw Exception("Unimplemented");
  }

  @override
  Future<void> setVPNExtensionEnabled(bool enabled) async {
    log("api: setVPNExtensionEnabled: $enabled");
    if (enabled) {
      await publishConfiguration();
      await _platform.invokeMethod('connect');
    } else {
      await _platform.invokeMethod('disconnect');
    }
  }

  Future<String> groupContainerPath() async {
    return await _platform.invokeMethod('group_path');
  }

  Future<String> versionString() async {
    return await _platform.invokeMethod('version');
  }

  // Generate the portion of the VPN config managed by the GUI.  Managed config
  // precedes user config in the tunnel, supporting overrides.
  // The desired format is (JavaScript, not JSON) e.g.:
  static Future<String> generateManagedConfig() async {
    // Circuit configuration
    var managedConfig = (await UserPreferencesVPN().routingEnabled.get()!)
        ? await OrchidVPNConfigGenerate.generateConfig()
        : "";

    // Inject the default (main net Ethereum) RPC provider
    managedConfig += '\nrpc = "${Chains.Ethereum.providerUrl}";';

    // Inject the status socket name
    managedConfig += '\ncontrol = "${OrchidRoutingStatus.socketName}";';

    // 'logdb' sets the analysis file location.
    // To disable monitoring set 'logdb' to an empty string.
    final pathOrEmptyString = UserPreferencesVPN().monitoringEnabled.get()!
        ? AnalysisDb.defaultAnalysisFilename
        : '';
    managedConfig += '\nlogdb="$pathOrEmptyString";';

    return managedConfig;
  }

  // Generate the combined user config and generated config
  static Future<String> generateCombinedConfig() async {
    var userConfig = UserPreferencesUI().userConfig.get();

    // Append the generated config before saving.
    String generatedConfig;
    try {
      generatedConfig = await generateManagedConfig();
    } catch (err, stack) {
      log("api: Error rendering config: $err\n$stack");
      generatedConfig = " ";
    }

    // Concatenate the user config and generated config
    var combinedConfig = generatedConfig + "\n" + (userConfig ?? "");
    return combinedConfig;
  }

  /// Publish the latest configuration to the VPN.
  Future<bool> publishConfiguration() async {
    log("api: update configuration");
    var combinedConfig = await generateCombinedConfig();
    log("api: combined config = {$combinedConfig}");
    var path = await groupContainerPath() + '/orchid.cfg';
    log("api: write config file: $path");
    try {
      // Write a UTF-8 string and flush.
      await File(path).writeAsString(combinedConfig, flush: true);
      return true;
    } catch (err) {
      log("api: write config file failed: $err");
      return false;
    }
  }

  void dispose() {
    vpnExtensionStatus.close();
    circuitConfigurationChanged.close();
    vpnRoutingStatus.close();
    vpnPermissionStatus.close();
  }
}
