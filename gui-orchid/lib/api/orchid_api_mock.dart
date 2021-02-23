import 'dart:async';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_api_real.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/ip_address.dart';
import 'package:orchid/util/location.dart';
import 'package:rxdart/rxdart.dart';
import 'orchid_budget_api.dart';
import 'orchid_log_api.dart';
import 'orchid_pricing.dart';

///
/// Mock Orchid App Channel API Implementation
///
class MockOrchidAPI implements OrchidAPI {
  static final MockOrchidAPI _singleton = MockOrchidAPI._internal();

  factory MockOrchidAPI() {
    return _singleton;
  }

  MockOrchidAPI._internal() {
    debugPrint("constructed mock API");
    _initChannel();
  }

  /// Publish the physical layer level network connectivity type.
  final networkConnectivity = BehaviorSubject<NetworkConnectivityType>.seeded(
      NetworkConnectivityType.Unknown);

  /// Publish the connection status.
  final vpnConnectionStatus = BehaviorSubject<OrchidVPNConnectionState>();

  /// Publish the orchid network connection status.
  final BehaviorSubject<OrchidConnectionState> connectionStatus =
      BehaviorSubject<OrchidConnectionState>.seeded(
          OrchidConnectionState.Invalid);

  /// Publish the network route status.
  final routeStatus = BehaviorSubject<OrchidRoute>();

  /// Publishes a status of true if the user has granted any necessary OS level permissions to allow
  /// installation and activation of the Orchid VPN networking extension.
  /// Note: On iOS this corresponds to having successfully saved the Orchid VPN configuration via the
  /// NEVPNManager API.
  final vpnPermissionStatus = BehaviorSubject<bool>();

  final circuitConfigurationChanged = BehaviorSubject<void>.seeded(null);

  OrchidLogAPI _logAPI = MemoryOrchidLogAPI();

  Timer _routeTimer;

  /// Initialize the Channel implementation.
  /// This method is called once when the application is initialized.
  void _initChannel() {
    // init connection status
    vpnConnectionStatus.add(OrchidVPNConnectionState.NotConnected);

    // Update the orchid connection state when the vpn or (mock) orchid
    // tunnel connection state changes.
    vpnConnectionStatus.listen((OrchidVPNConnectionState state) {
      switch(state) {
        case OrchidVPNConnectionState.Invalid:
          connectionStatus.add(OrchidConnectionState.Invalid);
          break;
        case OrchidVPNConnectionState.NotConnected:
          connectionStatus.add(OrchidConnectionState.VPNNotConnected);
          break;
        case OrchidVPNConnectionState.Connecting:
          connectionStatus.add(OrchidConnectionState.VPNConnecting);
          break;
        case OrchidVPNConnectionState.Connected:
          // mock api maps vpn connected to orchid connected
          connectionStatus.add(OrchidConnectionState.OrchidConnected);
          break;
        case OrchidVPNConnectionState.Disconnecting:
          connectionStatus.add(OrchidConnectionState.VPNDisconnecting);
          break;
      }
    });

    // fake route updates
    routeStatus.add(_fakeRoute());
    _routeTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      routeStatus.add(_fakeRoute());
    });

    // vpn configuration / permission status
    vpnPermissionStatus.add(false);
  }

  // fake route
  OrchidRoute _fakeRoute() {
    return OrchidRoute([
      // @formatter:off
      OrchidNode(ip: IPAddress.random(), location: Location.SFO),
      OrchidNode(ip: IPAddress.random(), location: Location.StraightOfGibralter),
      OrchidNode(ip: IPAddress.random(), location: Location.PEK),
      OrchidNode(ip: IPAddress.random(), location: Location.SoutherTipOfAfrica),
      OrchidNode(ip: IPAddress.random(), location: Location.CapeHorn),
      OrchidNode(ip: IPAddress.random(), location: Location.STL),
      // @formatter:on
    ]);
  }

  /// The Flutter application uses this method to indicate to the native channel code
  /// that the UI has finished launching and all listeners have been established.
  Future<void> applicationReady() {
    budget().applicationReady();
    return null;
  }

  /// Get the logging API.
  @override
  OrchidLogAPI logger() {
    return _logAPI;
  }

  /// Trigger a request for OS level permissions required to allow installation and activation of the
  /// Orchid VPN networking extension, potentially causing the OS to prompt the user.
  /// Returns true if the permission was granted.
  /// Note: On iOS this corresponds to an attempt to save the Orchid VPN configuration via the
  /// NEVPNManager API.
  @override
  Future<bool> requestVPNPermission() async {
    vpnPermissionStatus.add(true);
    return true;
  }

  /// Remove the VPN networking extension.
  Future<void> revokeVPNPermission() async {
    OrchidAPI().vpnPermissionStatus.add(false);
  }

  OrchidWallet _wallet;

  /// Set or update the user's wallet info.
  /// Returns true if the wallet was successfully saved.
  /// TODO: Support more than one wallet?
  @override
  Future<bool> setWallet(OrchidWallet wallet) async {
    this._wallet = wallet;
    logger().write('Saved wallet');
    return wallet.private.privateKey.startsWith('fail') ? false : true;
  }

  /// Remove any stored wallet credentials.
  Future<void> clearWallet() async {
    this._wallet = null;
  }

  /// If a wallet has been configured this method returns the user-visible
  /// wallet info; otherwise this method returns null.
  @override
  Future<OrchidWalletPublic> getWallet() async {
    if (_wallet == null) {
      return null;
    }
    return _wallet.public;
  }

  VPNConfig _exitVPNConfig;

  /// Set or update the user's exit VPN config.
  /// Return true if the configuration was saved successfully.
  @override
  Future<bool> setExitVPNConfig(VPNConfig vpnConfig) async {
    if (vpnConfig.public.userName.startsWith("fail")) {
      return false;
    }
    this._exitVPNConfig = vpnConfig;
    return true;
  }

  /// If an extenral VPN has been configured this method returns the user-visible
  /// VPN configuration; otherwise this method returns null.
  @override
  Future<VPNConfigPublic> getExitVPNConfig() async {
    if (_exitVPNConfig == null) {
      return null;
    }
    return _exitVPNConfig.public;
  }

  Future<void> _connectFuture;

  /// Set the desired connection state: true for connected, false to disconnect.
  /// Note: This mock shows the connecting state for N seconds and then connects
  /// Note: successfully.
  /// TODO: Cancelling the mock connecting phase should cancel the future connect.
  @override
  Future<void> setConnected(bool connect) async {
    switch (vpnConnectionStatus.value) {
      case OrchidVPNConnectionState.Invalid:
      case OrchidVPNConnectionState.NotConnected:
      case OrchidVPNConnectionState.Disconnecting:
        if (connect) {
          _setConnectionState(OrchidVPNConnectionState.Connecting);
          _connectFuture = Future.delayed(Duration(milliseconds: 3000), () {
            _setConnectionState(OrchidVPNConnectionState.Connected);
          });
        } else {
          return; // redundant disconnect
        }
        break;
      case OrchidVPNConnectionState.Connecting:
      case OrchidVPNConnectionState.Connected:
      // TODO: This does not seem to work.  How do we cancel here?
      // Cancel any pending connect
        if (_connectFuture != null) {
          CancelableOperation.fromFuture(_connectFuture).cancel();
          _connectFuture = null;
        }

        if (!connect) {
          _setConnectionState(OrchidVPNConnectionState.NotConnected);
        } else {
          return; // redundant connect
        }
        break;
    }
  }

  /// Choose a new, randomized, network route.
  @override
  Future<void> reroute() async {}

  void _setConnectionState(OrchidVPNConnectionState state) {
    logger().write('Connection state: $state');
    vpnConnectionStatus.add(state);
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
    return '/Users/pat/Desktop/table_flutter';
  }

  /// The build version
  Future<String> versionString() async {
    return "1.0.0";
  }

  // TODO: Copied from orchid_api_real, combine.
  /// Get the Orchid Configuration file contents
  Future<String> getConfiguration() async {
    // return _platform.invokeMethod('get_config');
    // Return only the user visible portion of the config.
    return await UserPreferences().getUserConfig();
  }

  // TODO: Copied from orchid_api_real, combine.
  /// Set the Orchid Configuration file contents
  Future<bool> setConfiguration(String userConfig) async {
    var combinedConfig = await RealOrchidAPI.generateCombinedConfig(userConfig);
    log("api fake: combinedConfig = $combinedConfig");
    // Do nothing.  Fake save.
    return true;
  }

  /// Publish the latest configuration to the VPN.
  Future<bool> updateConfiguration() async {
    return setConfiguration(await UserPreferences().getUserConfig());
  }

  void dispose() {
    vpnConnectionStatus.close();
    networkConnectivity.close();
    circuitConfigurationChanged.close();
    connectionStatus.close();
    routeStatus.close();
    vpnPermissionStatus.close();
  }
}
