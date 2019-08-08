import 'package:orchid/api/orchid_api_real.dart';
import 'package:orchid/api/orchid_api_mock.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/pages/settings/developer_settings.dart';
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

  /// Publish the connection status.
  final BehaviorSubject<OrchidConnectionState> connectionStatus;

  /// Publish the synchronization status.
  final BehaviorSubject<OrchidSyncStatus> syncStatus;

  /// Publish the network route status.
  final BehaviorSubject<OrchidRoute> routeStatus;

  /// Publishes a status of true if the user has granted any necessary OS level permissions to allow
  /// installation and activation of the Orchid VPN networking extension.
  /// Note: On iOS this corresponds to having successfully saved the Orchid VPN configuration via the
  /// NEVPNManager API.
  final BehaviorSubject<bool> vpnPermissionStatus;

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

  /// Get a map of name-value pairs representing dynamic developer settings.
  /// See [DeveloperSettings] for the list of default settings.
  Future<Map<String,String>> getDeveloperSettings();

  /// Set a name-value pair representing a dynamic developer settings
  void setDeveloperSetting({String name, String value});

  /// Placeholder API for funds and budgeting
  OrchidBudgetAPI budget();

  /// The the path for files shared between the 
  Future<String> groupContainerPath();

  /// The build version
  Future<String> versionString();
}


