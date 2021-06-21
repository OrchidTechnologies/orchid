import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../orchid_log_api.dart';
import 'accounts_preferences.dart';

class UserPreferences {
  static final UserPreferences _singleton = UserPreferences._internal();

  factory UserPreferences() {
    return _singleton;
  }

  UserPreferences._internal() {
    debugPrint("constructed user prefs API");
  }

  static Future<SharedPreferences> sharedPreferences() {
    return SharedPreferences.getInstance();
  }

  static Future<String> readStringForKey(UserPreferenceKey key) async {
    return (await sharedPreferences()).getString(key.toString());
  }

  // This method accepts null for property removal.
  static Future<bool> writeStringForKey(
      UserPreferenceKey key, String value) async {
    var shared = await sharedPreferences();
    if (value == null) {
      return await shared.remove(key.toString());
    }
    return await shared.setString(key.toString(), value);
  }

  ///
  /// Onboarding pages related preferences
  /// TODO: Replace these with one StringList?
  ///

  /// Was the user prompted for the necessary permissions to install the VPN
  /// extension as part of onboarding
  Future<bool> getPromptedForVPNPermission() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.PromptedForVPNPermission.toString()) ??
        false;
  }

  /// Was the user prompted for the necessary permissions to install the VPN
  /// extension as part of onboarding
  Future<bool> setPromptedForVPNPermission(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.PromptedForVPNPermission.toString(), value);
  }

  // Set the circuit / hops configuration
  Future<bool> setCircuit(Circuit circuit) async {
    String value = jsonEncode(circuit);
    return writeStringForKey(UserPreferenceKey.Circuit, value);
  }

  // Get the circuit / hops configuration
  // This default to an empty [] circuit if uninitialized.
  Future<Circuit> getCircuit() async {
    String value = (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.Circuit.toString());
    if (value == null) {
      return Circuit([]);
    }
    return Circuit.fromJson(jsonDecode(value));
  }

  // Add a single hop to the recently deleted list
  void addRecentlyDeletedHop(CircuitHop hop) async {
    var hops = await getRecentlyDeleted();
    hops.hops.add(hop);
    await setRecentlyDeleted(hops);
  }

  // Store recently deleted hops
  Future<bool> setRecentlyDeleted(Hops hops) async {
    log("saving recently deleted hops: ${hops.hops}");
    String value = jsonEncode(hops);
    return writeStringForKey(UserPreferenceKey.RecentlyDeletedHops, value);
  }

  // Get a list of recently deleted hops.
  Future<Hops> getRecentlyDeleted() async {
    String value = (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.RecentlyDeletedHops.toString());
    if (value == null) {
      return Hops([]);
    }
    return Hops.fromJson(jsonDecode(value));
  }

  // Get the user editable configuration file text.
  Future<String> getUserConfig() async {
    return (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.UserConfig.toString());
  }

  // Set the user editable configuration file text.
  Future<bool> setUserConfig(String value) async {
    return writeStringForKey(UserPreferenceKey.UserConfig, value);
  }

  /// Return the user's keys or [] empty array if uninitialized.
  // Note: A format change or bug that causes a decoding error here would be bad.
  // Note: When we move these keys to secure storage the issues will change
  // Note: so we will rely on this for now.
  Future<List<StoredEthereumKey>> getKeys() async {
    String value = (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.Keys.toString());
    if (value == null) {
      return [];
    }
    try {
      var jsonList = jsonDecode(value) as List<dynamic>;
      return jsonList
          .map((el) {
            try {
              return StoredEthereumKey.fromJson(el);
            } catch (err) {
              log("Error decoding key: $err");
              return null;
            }
          })
          .where((key) => key != null)
          .toList();
    } catch (err) {
      log("Error retrieving keys!: $err");
      return [];
    }
  }

  Future<bool> setKeys(List<StoredEthereumKey> keys) async {
    print("setKeys: storing keys: ${jsonEncode(keys)}");
    try {
      var value = jsonEncode(keys);
      return writeStringForKey(UserPreferenceKey.Keys, value);
    } catch (err) {
      log("Error storing keys!: $err");
      return false;
    }
  }

  /// Add a key to the user's keystore.
  // Note: Minimizes exposure to the full setKeys()
  Future<bool> addKey(StoredEthereumKey key) async {
    var keys = ((await UserPreferences().getKeys()) ?? []) + [key];
    return UserPreferences().setKeys(keys);
  }

  /// Remove a key from the user's keystore.
  Future<bool> removeKey(StoredEthereumKeyRef keyRef) async {
    var keys = ((await UserPreferences().getKeys()) ?? []);
    try {
      keys.removeWhere((key) => key.uid == keyRef.keyUid);
    } catch (err) {
      log("account: error removing key: $keyRef");
      return false;
    }
    return UserPreferences().setKeys(keys);
  }

  /// Add a list of keys to the user's keystore.
  // Note: Minimizes exposure to the full setKeys()
  Future<bool> addKeys(List<StoredEthereumKey> newKeys) async {
    var keys = ((await UserPreferences().getKeys()) ?? []) + newKeys;
    return UserPreferences().setKeys(keys);
  }

  Future<String> getDefaultCurator() async {
    return (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.DefaultCurator.toString());
  }

  Future<bool> setDefaultCurator(String value) async {
    return writeStringForKey(UserPreferenceKey.DefaultCurator, value);
  }

  Future<bool> getQueryBalances() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.QueryBalances.toString()) ??
        true;
  }

  Future<bool> setQueryBalances(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.QueryBalances.toString(), value);
  }

  Future<bool> getShowStatusTab() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.ShowStatusTab.toString()) ??
        false;
  }

  Future<bool> setShowStatusTab(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.ShowStatusTab.toString(), value);
  }

  Future<bool> getVPNSwitchInstructionsViewed() async {
    return (await SharedPreferences.getInstance()).getBool(
            UserPreferenceKey.VPNSwitchInstructionsViewed.toString()) ??
        false;
  }

  Future<bool> setVPNSwitchInstructionsViewed(bool value) async {
    return (await SharedPreferences.getInstance()).setBool(
        UserPreferenceKey.VPNSwitchInstructionsViewed.toString(), value);
  }

  /// The PAC transaction or null if there is none.
  ObservablePreference<PacTransaction> pacTransaction = ObservablePreference(
      key: UserPreferenceKey.PacTransaction,
      loadValue: (key) async {
        String value = await readStringForKey(key);
        try {
          return value != null
              ? PacTransaction.fromJson(jsonDecode(value))
              : null;
        } catch (err) {
          log("pacs: Unable to decode v1 transaction, returning null: $value, $err");
          return null;
        }
      },
      storeValue: (key, tx) {
        String value = tx != null ? jsonEncode(tx) : null;
        return writeStringForKey(key, value);
      });

  /// A list of account information indicating the active identity (signer key)
  /// and the active account (funder and chainid) for that identity.
  /// The order of this list is significant in that the first account designates
  /// the active identity. The list should contain at most one account per identity.
  ObservablePreference<List<Account>> activeAccounts =
      ObservableAccountListPreference(UserPreferenceKey.ActiveAccounts);

  /// Add (set-wise) to the distinct set of discovered accounts.
  Future<void> addCachedDiscoveredAccounts(List<Account> accounts) async {
    if (accounts == null || accounts.isEmpty) {
      return;
    }
    var cached = await cachedDiscoveredAccounts.get();
    cached.addAll(accounts);
    cachedDiscoveredAccounts.set(cached);
  }

  /// A set of accounts previously discovered for user identities
  ObservablePreference<Set<Account>> cachedDiscoveredAccounts =
      ObservableAccountSetPreference(
          UserPreferenceKey.CachedDiscoveredAccounts);

  // Defaults false
  ObservableBoolPreference guiV0 =
      ObservableBoolPreference(UserPreferenceKey.GuiV0);

  /// An incrementing integer app release version used to track first launch
  /// and new release launch messaging.
  ObservablePreference<ReleaseVersion> releaseVersion = ObservablePreference(
      key: UserPreferenceKey.ReleaseVersion,
      loadValue: (key) async {
        return ReleaseVersion(
            (await SharedPreferences.getInstance()).getInt(key.toString()));
      },
      storeValue: (key, value) async {
        return (await SharedPreferences.getInstance())
            .setInt(key.toString(), value.version);
      });

  /// User preference indicating that the VPN should be enabled to route traffic
  /// per the user's hop configuration.
  /// Note that the actual state of the VPN subsystem is controlled by the OrchidAPI
  /// and may also take into account the monitoring preference.
  ObservableBoolPreference routingEnabled = ObservableBoolPreference(
      UserPreferenceKey.RoutingEnabled,
      defaultValue: false);

  /// User preference indicating that the Orchid VPN should be enabled to monitor traffic.
  /// Note that the actual state of the VPN subsystem is controlled by the OrchidAPI
  /// and may also take into account the vpn enabled preference.
  ObservableBoolPreference monitoringEnabled = ObservableBoolPreference(
      UserPreferenceKey.MonitoringEnabled,
      defaultValue: false);

  /// This is a synthetic preference that indicates that the user has set
  /// the monitoring preference enabled and the routing preference disabled.
  // Future<bool> monitorOnly() async {
  //   return (await monitoringEnabled.value) && (!await routingEnabled.value);
  // }
}

enum UserPreferenceKey {
  PromptedForVPNPermission,
  Circuit,
  RecentlyDeletedHops,
  UserConfig,
  Keys,
  DefaultCurator,
  QueryBalances,
  DesiredVPNState,
  ShowStatusTab,
  VPNSwitchInstructionsViewed,
  PacTransaction,
  ActiveAccounts,
  CachedDiscoveredAccounts,
  GuiV0,
  ReleaseVersion,
  RoutingEnabled,
  MonitoringEnabled,
}
