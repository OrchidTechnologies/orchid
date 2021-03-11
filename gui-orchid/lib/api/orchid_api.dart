import 'package:orchid/api/orchid_api_real.dart';
import 'package:orchid/api/orchid_api_mock.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:rxdart/rxdart.dart';
import 'orchid_budget_api.dart';
import 'orchid_log_api.dart';

///
/// Orchid App Channel API
///
abstract class OrchidAPI {
  static bool mockAPI = false;
  static OrchidAPI _apiSingleton;
  static OrchidAPI _mockAPISingleton;

  factory OrchidAPI() {
    if (mockAPI) {
      if (_mockAPISingleton == null) {
        _mockAPISingleton = MockOrchidAPI();
      }
    } else {
      if (_apiSingleton == null) {
        _apiSingleton = RealOrchidAPI();
      }
    }
    return mockAPI ? _mockAPISingleton : _apiSingleton;
  }

  /// Publish the physical layer level network connectivity type.
  final BehaviorSubject<NetworkConnectivityType> networkConnectivity;

  /// Publish the system VPN connection status.
  /// See also OrchidStatus for the app-level tunnel status.
  final BehaviorSubject<OrchidVPNConnectionState> vpnConnectionStatus;

  /// Publish the orchid network connection status.
  final BehaviorSubject<OrchidConnectionState> connectionStatus;

  /// Publish the network route status.
  final BehaviorSubject<OrchidRoute> routeStatus;

  /// Publishes a status of true if the user has granted any necessary OS level permissions to allow
  /// installation and activation of the Orchid VPN networking extension.
  /// Note: On iOS this corresponds to having successfully saved the Orchid VPN configuration via the
  /// NEVPNManager API.
  final BehaviorSubject<bool> vpnPermissionStatus;

  /// Publish notifications that the circuit hop configuration has changed.
  final BehaviorSubject<void> circuitConfigurationChanged;

  /// The Flutter application uses this method to indicate to the native channel code
  /// that the UI has finished launching and all listeners have been established.
  Future<void> applicationReady();

  /// Get the logging API.
  OrchidLogAPI logger();

  /// Trigger a request for OS level permission to allow installation and activation of the
  /// Orchid VPN networking extension, potentially causing the OS to prompt the user.
  /// Returns true if the permission was granted.
  /// Note: On iOS this corresponds to an attempt to save the Orchid VPN configuration via the
  /// NEVPNManager API.
  Future<bool> requestVPNPermission();

  /// Remove the VPN networking extension.
  Future<void> revokeVPNPermission();

  /// Set or update the user's wallet info.
  /// Returns true if the wallet was successfully saved.
  Future<bool> setWallet(OrchidWallet wallet);

  /// Remove any stored wallet credentials.
  Future<void> clearWallet();

  /// If a wallet has been configured this method returns the user-visible
  /// wallet info; otherwise this method returns null.
  Future<OrchidWalletPublic> getWallet();

  /// Set or update the user's external VPN config.
  /// Return true if the configuration was saved successfully.
  Future<bool> setExitVPNConfig(VPNConfig vpnConfig);

  /// If an extenral VPN has been configured this method returns the user-visible
  /// VPN configuration; otherwise this method returns null.
  Future<VPNConfigPublic> getExitVPNConfig();

  /// Set the desired connection state: true for connected, false to disconnect.
  Future<void> setConnected(bool connect);

  /// Choose a new, randomized, network route.
  Future<void> reroute();

  /// API for funds and budgeting
  OrchidBudgetAPI budget();

  /// The the path for files shared between the
  Future<String> groupContainerPath();

  /// The build version
  Future<String> versionString();

  /// Get the User visible Orchid Configuration file contents
  Future<String> getConfiguration();

  /// Set the User visible Orchid Configuration file contents
  /// and publish it to the VPN.
  /// Returns true if the configuration was saved successfully.
  Future<bool>setConfiguration(String userConfig);

  /// Publish the latest configuration to the VPN.
  Future<bool> updateConfiguration();

  void dispose() {
    vpnConnectionStatus.close();
    networkConnectivity.close();
    circuitConfigurationChanged.close();
    connectionStatus.close();
    routeStatus.close();
    vpnPermissionStatus.close();
  }
}


