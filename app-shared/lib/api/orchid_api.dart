import 'package:orchid/api/orchid_api_real.dart';
import 'package:orchid/api/orchid_api_mock.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:rxdart/rxdart.dart';

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
  final BehaviorSubject<bool> networkingPermissionStatus;

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
}

/// Logging support, if any, implemented by the channel API.
abstract class OrchidLogAPI {

  /// Notify observers when the log file has updated.
  PublishSubject<void> logChanged = PublishSubject<void>();

  /// Enable or disable logging.
  Future<void> setEnabled(bool enabled);

  /// Get the logging enabled status.
  Future<bool> getEnabled();

  /// Get the current log contents.
  Future<String> get();

  /// Write the text to the log.
  void write(String text);

  /// Clear the log file.
  void clear();
}
