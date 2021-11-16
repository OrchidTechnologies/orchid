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
  static bool mockAPI = const bool.hasEnvironment('mock');
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

  /// The system VPN extension connection status.
  final BehaviorSubject<OrchidVPNExtensionState> vpnExtensionStatus;

  /// The Orchid routing state, which is a superset of the vpn extension status
  /// but only reflects how routing is affected.
  final BehaviorSubject<OrchidVPNRoutingState> vpnRoutingStatus;

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

  /// Start or stop the vpn extension at the OS level:
  /// When the VPN is enabled it is capturing packets and routing them as
  /// specified by its configuration file.
  Future<void> setVPNExtensionEnabled(bool enabled);

  /// API for funds and budgeting
  OrchidBudgetAPI budget();

  /// The the base path for files shared between the UI and VPN extension.
  /// e.g. groupContainerPath() + '/analysis.db'
  Future<String> groupContainerPath();

  /// The build version
  Future<String> versionString();

  /// Publish the latest configuration file to the VPN.
  Future<bool> publishConfiguration();

  void dispose() {
    circuitConfigurationChanged.close();
    vpnRoutingStatus.close();
    vpnPermissionStatus.close();
    vpnExtensionStatus.close();
    vpnRoutingStatus.close();
  }
}
