import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../orchid_log_api.dart';
import 'accounts_preferences.dart';

class UserPreferences {
  static final UserPreferences _singleton = UserPreferences._internal();

  factory UserPreferences() {
    return _singleton;
  }

  UserPreferences._internal() {
    debugPrint("Constructed user prefs API");
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
  /// Begin: Circuit
  ///

  ObservablePreference<Circuit> circuit = ObservablePreference(
      key: UserPreferenceKey.Circuit,
      loadValue: (key) async {
        return _getCircuit();
      },
      storeValue: (key, circuit) {
        return _setCircuit(circuit);
      });

  @deprecated
  Future<Circuit> getCircuit() async {
    return _getCircuit();
  }

  // Set the circuit / hops configuration
  static Future<bool> _setCircuit(Circuit circuit) async {
    String value = circuit != null ? jsonEncode(circuit) : null;
    return writeStringForKey(UserPreferenceKey.Circuit, value);
  }

  // Get the circuit / hops configuration
  // This default to an empty [] circuit if uninitialized.
  static Future<Circuit> _getCircuit() async {
    String value = (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.Circuit.toString());
    if (value == null) {
      return Circuit([]);
    }
    return Circuit.fromJson(jsonDecode(value));
  }

  ///
  /// End: Circuit
  ///

  // Get the user editable configuration file text.
  // Future<String> getUserConfig() async {
  //   return (await SharedPreferences.getInstance())
  //       .getString(UserPreferenceKey.UserConfig.toString());
  // }

  // Set the user editable configuration file text.
  // Future<bool> setUserConfig(String value) async {
  //   return writeStringForKey(UserPreferenceKey.UserConfig, value);
  // }

  /// The user-editable portion of the configuration file text.
  ObservableStringPreference userConfig =
      ObservableStringPreference(UserPreferenceKey.UserConfig);

  ///
  /// Begin: Keys
  ///

  /// Return the user's keys or [] empty array if uninitialized.
  ObservablePreference<List<StoredEthereumKey>> keys = ObservablePreference(
      key: UserPreferenceKey.Keys,
      loadValue: (key) async {
        return _getKeys();
      },
      storeValue: (key, keys) {
        return _setKeys(keys);
      });

  /// Return the user's keys or [] empty array if uninitialized.
  static Future<List<StoredEthereumKey>> _getKeys() async {
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

  static Future<bool> _setKeys(List<StoredEthereumKey> keys) async {
    print("setKeys: storing keys: ${jsonEncode(keys)}");
    try {
      var value = jsonEncode(keys);
      return await writeStringForKey(UserPreferenceKey.Keys, value);
    } catch (err) {
      log("Error storing keys!: $err");
      return false;
    }
  }

  /// Return the user's keys or [] empty array if uninitialized.
  @deprecated
  Future<List<StoredEthereumKey>> getKeys() async {
    return keys.get();
  }

  /// Add a key to the user's keystore.
  // Note: Minimizes exposure to the full setKeys()
  Future<void> addKey(StoredEthereumKey key) async {
    var allKeys = ((await keys.get()) ?? []) + [key];
    return await keys.set(allKeys);
  }

  /// Remove a key from the user's keystore.
  Future<bool> removeKey(StoredEthereumKeyRef keyRef) async {
    var keysList = ((await keys.get()) ?? []);
    try {
      keysList.removeWhere((key) => key.uid == keyRef.keyUid);
    } catch (err) {
      log("account: error removing key: $keyRef");
      return false;
    }
    await keys.set(keysList);
    return true;
  }

  /// Add a list of keys to the user's keystore.
  Future<void> addKeys(List<StoredEthereumKey> newKeys) async {
    var allKeys = ((await keys.get()) ?? []) + newKeys;
    return await keys.set(allKeys);
  }

  ///
  /// End: Keys
  ///

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

  // TODO: Currently maintained only for use in migration to new circuit builder.
  /// A list of account information indicating the active identity (signer key)
  /// and the active account (funder and chainid) for that identity.
  /// The order of this list is significant in that the first account designates
  /// the active identity for routing.  The remaining items in the list serve
  /// as a history of previous account selections for the respective identities.
  /// Identities should appear in this list only once.
  /// @See Account.activeAccount
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
  /// Returns {} empty set initially.
  ObservablePreference<Set<Account>> cachedDiscoveredAccounts =
      ObservableAccountSetPreference(
          UserPreferenceKey.CachedDiscoveredAccounts);

  /// An incrementing internal UI app release notes version used to track
  /// new release messaging.  See class [Release]
  ObservablePreference<ReleaseVersion> releaseVersion = ObservablePreference(
      key: UserPreferenceKey.ReleaseVersion,
      loadValue: (key) async {
        return ReleaseVersion(
            (await SharedPreferences.getInstance()).getInt(key.toString()));
      },
      storeValue: (key, value) async {
        var sharedPreferences = await SharedPreferences.getInstance();
        if (value.version == null) {
          return sharedPreferences.remove(key.toString());
        }
        return sharedPreferences.setInt(key.toString(), value.version);
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
}

enum UserPreferenceKey {
  Circuit,
  UserConfig,
  Keys,
  DefaultCurator,
  QueryBalances,
  PacTransaction,
  ActiveAccounts,
  CachedDiscoveredAccounts,
  ReleaseVersion,
  RoutingEnabled,
  MonitoringEnabled,
}
