import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
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

  // This method accepts null as equivalent to removing the preference.
  static Future<void> writeStringForKey(
      UserPreferenceKey key, String value) async {
    return await (await sharedPreferences()).setString(key.toString(), value);
  }

  // Get the user editable configuration file text.
  Future<String> getUserConfig() async {
    return (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.UserConfig.toString());
  }

  // Set the user editable configuration file text.
  Future<bool> setUserConfig(String value) async {
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.UserConfig.toString(), value);
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
      return (await SharedPreferences.getInstance())
          .setString(UserPreferenceKey.Keys.toString(), jsonEncode(keys));
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

  // TODO: Remove (For compatability wiht some of the app code)
  ObservablePreference<bool> guiV0 = ObservablePreference(
      key: UserPreferenceKey.GuiV0,
      loadValue: (key) async {
        return true;
      },
      storeValue: (key, value) async {
        throw Exception();
      });

}

// TODO: Remove unneeded items.
enum UserPreferenceKey {
  UserConfig,
  Keys,
  ActiveAccounts,
  CachedDiscoveredAccounts,
  GuiV0,
}
