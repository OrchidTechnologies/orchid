import 'dart:convert';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/preferences/user_preferences_keys.dart';
import 'package:orchid/vpn/preferences/user_preferences_mock.dart';
import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/vpn/purchase/orchid_pac_transaction.dart';
import 'package:orchid/vpn/model/circuit.dart';
import 'accounts_preferences.dart';
import 'release_version.dart';

class UserPreferencesVPN {
  static final UserPreferencesVPN _singleton = UserPreferencesVPN._internal();

  factory UserPreferencesVPN() {
    return _singleton;
  }

  UserPreferencesVPN._internal();

  ///
  /// Begin: Circuit
  ///

  /// Save the circuit and update published config and configuration listeners
  Future<void> saveCircuit(Circuit circuit) async {
    try {
      //log("Saving circuit: ${circuit.hops.map((e) => e.toJson())}");
      await UserPreferencesVPN().circuit.set(circuit);
    } catch (err, stack) {
      log("Error saving circuit: $err, $stack");
    }
    await OrchidAPI().publishConfiguration();
    OrchidAPI().circuitConfigurationChanged.add(null);
  }

  ObservablePreference<Circuit> circuit = ObservablePreference(
      key: _UserPreferenceKeyVPN.Circuit,
      getValue: (key) {
        return _getCircuit();
      },
      putValue: (key, circuit) {
        return _setCircuit(circuit ?? Circuit([]));
      });

  // Set the circuit / hops configuration
  static Future<bool> _setCircuit(Circuit circuit) async {
    String value = jsonEncode(circuit);
    return UserPreferences()
        .putStringForKey(_UserPreferenceKeyVPN.Circuit, value);
  }

  // Get the circuit / hops configuration
  // This default to an empty [] circuit if uninitialized.
  static Circuit _getCircuit() {
    if (AccountMock.mockAccounts) {
      return UserPreferencesMock.mockCircuit;
    }
    String? value =
        UserPreferences().getStringForKey(_UserPreferenceKeyVPN.Circuit);
    return value == null ? Circuit([]) : Circuit.fromJson(jsonDecode(value));
  }

  ///
  /// End: Circuit
  ///

  String? getDefaultCurator() {
    return UserPreferences()
        .getStringForKey(_UserPreferenceKeyVPN.DefaultCurator);
  }

  Future<bool> setDefaultCurator(String value) async {
    return UserPreferences()
        .putStringForKey(_UserPreferenceKeyVPN.DefaultCurator, value);
  }

  bool getQueryBalances() {
    return UserPreferences()
            .sharedPreferences()
            .getBool(_UserPreferenceKeyVPN.QueryBalances.toString()) ??
        true;
  }

  Future<bool> setQueryBalances(bool value) async {
    return UserPreferences()
        .sharedPreferences()
        .setBool(_UserPreferenceKeyVPN.QueryBalances.toString(), value);
  }

  /// The PAC transaction or null if there is none.
  ObservablePreference<PacTransaction?> pacTransaction = ObservablePreference(
      key: _UserPreferenceKeyVPN.PacTransaction,
      getValue: (key) {
        String? value = UserPreferences().getStringForKey(key);
        try {
          return value != null
              ? PacTransaction.fromJson(jsonDecode(value))
              : null;
        } catch (err) {
          log("pacs: Unable to decode v1 transaction, returning null: $value, $err");
          return null;
        }
      },
      putValue: (key, tx) {
        String? value = tx != null ? jsonEncode(tx) : null;
        return UserPreferences().putStringForKey(key, value);
      });

  /// Add to the set of discovered accounts.
  Future<void> addCachedDiscoveredAccounts(List<Account> accounts) async {
    if (accounts.isEmpty) {
      return;
    }
    if (accounts.contains(null)) {
      throw Exception('null account in add to cache');
    }
    var cached =
        cachedDiscoveredAccounts.get() ?? {}; // won't actually return null
    cached.addAll(accounts);
    await cachedDiscoveredAccounts.set(cached);
  }

  Future<void> addAccountsIfNeeded(List<Account> accounts) async {
    // Allow the set to prevent duplication.
    log("XXX: adding accounts: $accounts");
    return addCachedDiscoveredAccounts(accounts);
  }

  /// A set of accounts previously discovered for user identities
  /// Returns {} empty set initially.
  ObservablePreference<Set<Account>> cachedDiscoveredAccounts =
      ObservableAccountSetPreference(
          _UserPreferenceKeyVPN.CachedDiscoveredAccounts);

  /// Add a potentially new identity (signer key) and account (funder, chain, version)
  /// without duplication.
  Future<void> ensureSaved(Account account) async {
    await UserPreferencesKeys().addKeyIfNeeded(account.signerKey);
    await UserPreferencesVPN()
        .addCachedDiscoveredAccounts([account]); // setwise, safe
  }

  /// An incrementing internal UI app release notes version used to track
  /// new release messaging.  See class [Release]
  ObservablePreference<ReleaseVersion> releaseVersion = ObservablePreference(
      key: _UserPreferenceKeyVPN.ReleaseVersion,
      getValue: (key) {
        return ReleaseVersion(
            (UserPreferences().sharedPreferences()).getInt(key.toString()));
      },
      putValue: (key, value) async {
        var sharedPreferences = UserPreferences().sharedPreferences();
        if (value?.version == null) {
          return sharedPreferences.remove(key.toString());
        }
        return sharedPreferences.setInt(key.toString(), value!.version!);
      });

  /// User preference indicating that the VPN should be enabled to route traffic
  /// per the user's hop configuration.
  /// Note that the actual state of the VPN subsystem is controlled by the OrchidAPI
  /// and may also take into account the monitoring preference.
  ObservableBoolPreference routingEnabled = ObservableBoolPreference(
      _UserPreferenceKeyVPN.RoutingEnabled,
      defaultValue: false);

  /// User preference indicating that the Orchid VPN should be enabled to monitor traffic.
  /// Note that the actual state of the VPN subsystem is controlled by the OrchidAPI
  /// and may also take into account the vpn enabled preference.
  ObservableBoolPreference monitoringEnabled = ObservableBoolPreference(
      _UserPreferenceKeyVPN.MonitoringEnabled,
      defaultValue: false);
}

enum _UserPreferenceKeyVPN implements UserPreferenceKey {
  Circuit,
  DefaultCurator,
  QueryBalances,
  PacTransaction,
  CachedDiscoveredAccounts,
  ReleaseVersion,
  RoutingEnabled,
  MonitoringEnabled,
}
