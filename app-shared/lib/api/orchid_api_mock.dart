import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/util/ip_address.dart';
import 'package:rxdart/rxdart.dart';

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

  Timer _routeTimer;

  /// Initialize the Channel implementation.
  /// This method is called once when the application is initialized.
  void _initChannel() {
    // init connection status
    connectionStatus.add(OrchidConnectionState.NotConnected);

    // fake sync progress
    syncStatus.add(
        OrchidSyncStatus(state: OrchidSyncState.InProgress, progress: 0.5));

    // fake route updates
    routeStatus.add(_randomRoute());
    _routeTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      routeStatus.add(_randomRoute());
    });

    // vpn configuration / permission status
    networkingPermissionStatus.add(false);
  }

  // fake route
  OrchidRoute _randomRoute() {
    return OrchidRoute([
      OrchidNode(ip: IPAddress.random(), location: OrchidNodeLocation()),
      OrchidNode(ip: IPAddress.random(), location: OrchidNodeLocation()),
      OrchidNode(ip: IPAddress.random(), location: OrchidNodeLocation())
    ]);
  }

  /// Publish the connection status.
  //
  // Usage: The channel implementation publishes with:
  //   connectionStatus.add(latestState)
  // Application components receive updates with:
  //   connectionStatus.listen((state) { ... } )
  //
  final connectionStatus = BehaviorSubject<OrchidConnectionState>();

  /// Publish the synchronization status.
  final syncStatus = BehaviorSubject<OrchidSyncStatus>();

  /// Publish the network route status.
  final routeStatus = BehaviorSubject<OrchidRoute>();

  /// Publishes a status of true if the user has granted any necessary OS level permissions to allow
  /// installation and activation of the Orchid VPN networking extension.
  /// Note: On iOS this corresponds to having successfully saved the Orchid VPN configuration via the
  /// NEVPNManager API.
  final networkingPermissionStatus = BehaviorSubject<bool>();

  /// Publish development logging information from the channel implementation.
  final log = PublishSubject<String>();

  /// Trigger a request for OS level permissions required to allow installation and activation of the
  /// Orchid VPN networking extension, potentially causing the OS to prompt the user.
  /// Returns true if the permission was granted.
  /// Note: On iOS this corresponds to an attempt to save the Orchid VPN configuration via the
  /// NEVPNManager API.
  @override
  Future<bool> requestVPNPermission() async {
    networkingPermissionStatus.add(true);
    return true;
  }

  /// Remove the VPN networking extension.
  Future<void> revokeVPNPermission() async {
    OrchidAPI().networkingPermissionStatus.add(false);
  }

  OrchidWallet _wallet;

  /// Set or update the user's wallet info.
  /// Returns true if the wallet was successfully saved.
  /// TODO: Support more than one wallet?
  @override
  Future<bool> setWallet(OrchidWallet wallet) async {
    this._wallet = wallet;
    log.add("Saved wallet");
    return wallet.private.privateKey.startsWith("fail") ? false : true;
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
  /// TODO: Support more than one VPN config?
  /// Return true if the configuration was saved successfully.
  @override
  Future<bool> setExitVPNConfig(VPNConfig vpnConfig) async {
    this._exitVPNConfig = vpnConfig;
    return vpnConfig.public.userName.startsWith("fail") ? false : true;
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

  /// Enable or disable log messages from the channel implementation.
  @override
  Future<void> setLogging(bool enabled) async {
    // TODO:
  }

  Future<void> _connectFuture;

  /// Set the desired connection state: true for connected, false to disconnect.
  /// Note: This mock shows the connecting state for N seconds and then connects
  /// Note: successfully.
  /// TODO: Cancelling the mock connecting phase should cancel the future connect.
  @override
  Future<void> setConnected(bool connect) async {
    switch (connectionStatus.value) {
      case OrchidConnectionState.NotConnected:
        if (connect) {
          _setConnectionState(OrchidConnectionState.Connecting);
          _connectFuture = Future.delayed(Duration(seconds: 1), () {
            _setConnectionState(OrchidConnectionState.Connected);
          });
        } else {
          return; // redundant disconnect
        }
        break;
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.Connected:
        // TODO: This does not seem to work.  How do we cancel here?
        // Cancel any pending connect
        if (_connectFuture != null) {
          CancelableOperation.fromFuture(_connectFuture).cancel();
          _connectFuture = null;
        }

        if (!connect) {
          _setConnectionState(OrchidConnectionState.NotConnected);
        } else {
          return; // redundant connect
        }
        break;
    }
  }

  /// Choose a new, randomized, network route.
  @override
  Future<void> reroute() async {}

  void _setConnectionState(OrchidConnectionState state) {
    log.add("Connection state: $state");
    connectionStatus.add(state);
  }
}
