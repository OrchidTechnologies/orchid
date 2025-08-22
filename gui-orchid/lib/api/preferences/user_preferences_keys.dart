import 'dart:convert';
import 'user_preferences.dart';
import 'package:orchid/api/orchid_keys.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';

class UserPreferencesKeys {
  static final UserPreferencesKeys _singleton = UserPreferencesKeys._internal();

  factory UserPreferencesKeys() {
    return _singleton;
  }

  UserPreferencesKeys._internal();

  ///
  /// Begin: Keys
  ///

  /// Return the user's keys or [] empty array if uninitialized.
  ObservablePreference<List<StoredEthereumKey>> keys = ObservablePreference(
      key: _UserPreferenceKeyKeys.Keys,
      getValue: (key) {
        return _getKeys();
      },
      putValue: (key, keys) {
        return _setKeys(keys);
      });

  /// Return the user's keys or [] empty array if uninitialized.
  static List<StoredEthereumKey> _getKeys() {
    log("UserPreferenceKeys: getKeys: retrieving keys");
    if (AccountMock.mockAccounts) {
      return AccountMock.mockKeys;
    }

    String? value =
        UserPreferences().getStringForKey(_UserPreferenceKeyKeys.Keys);
    if (value == null) {
      log("UserPreferenceKeys: getKeys: no keys found, returning empty list");
      return [];
    }
    try {
      var jsonList = jsonDecode(value) as List<dynamic>;
      // log("UserPreferenceKeys: getKeys: found keys: $jsonList");
      return jsonList
          .map((el) {
            try {
              return StoredEthereumKey.fromJson(el);
            } catch (err) {
              log("UserPreferenceKeys: Error decoding key: $err");
              return null;
            }
          })
          .whereType<StoredEthereumKey>()
          .toList();
    } catch (err) {
      log("UserPreferenceKeys: Error retrieving keys!: $value, $err");
      return [];
    }
  }

  static Future<bool> _setKeys(List<StoredEthereumKey>? keys) async {
    // log("UserPreferenceKeys: setKeys: storing keys: ${jsonEncode(keys)}");
    if (keys == null) {
      log("UserPreferenceKeys: setKeys: removing keys");
      return await UserPreferences().remove(_UserPreferenceKeyKeys.Keys);
    }
    try {
      var value = jsonEncode(keys);
      return await UserPreferences()
          .putStringForKey(_UserPreferenceKeyKeys.Keys, value);
    } catch (err) {
      log("UserPreferenceKeys: Error storing keys!: $err");
      return false;
    }
  }

  /// Remove a key from the user's keystore.
  Future<bool> removeKey(StoredEthereumKeyRef keyRef) async {
    var keysList = ((keys.get()) ?? []);
    try {
      keysList.removeWhere((key) => key.uid == keyRef.keyUid);
    } catch (err) {
      log("UserPreferenceKeys: account: error removing key: $keyRef");
      return false;
    }
    await keys.set(keysList);
    return true;
  }

  /// Add a key to the user's keystore if it does not already exist.
  Future<void> addKey(StoredEthereumKey key) async {
    return addKeyIfNeeded(key);
  }

  /// Add a key to the user's keystore if it does not already exist.
  Future<void> addKeyIfNeeded(StoredEthereumKey key) async {
    log("UserPreferenceKeys: addKeyIfNeeded: add key if needed: $key");
    var curKeys = keys.get() ?? [];
    if (!curKeys.contains(key)) {
      log("UserPreferenceKeys: addKeyIfNeeded: adding key");
      await keys.set(curKeys + [key]);
    } else {
      log("UserPreferenceKeys: addKeyIfNeeded: duplicate key");
    }
  }

  /// Add a list of keys to the user's keystore.
  Future<void> addKeys(List<StoredEthereumKey> newKeys) async {
    var allKeys = ((keys.get()) ?? []) + newKeys;
    await keys.set(allKeys);
  }

  ///
  /// End: Keys
  ///
}

enum _UserPreferenceKeyKeys implements UserPreferenceKey {
  Keys,
}
