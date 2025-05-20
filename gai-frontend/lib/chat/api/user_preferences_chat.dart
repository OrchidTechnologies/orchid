import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/preferences/user_preferences.dart';

class UserScript {
  // A user-entered name for the script entry.
  final String name;

  // The script body, or, if script begins with 'https' a URL from which to fetch the script.
  final String script;

  // Whether the script is selected for use.
  final bool selected;

  UserScript(this.name, this.script, this.selected);

  UserScript.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        script = json['script'],
        selected = json['selected'];

  Map<String, dynamic> toJson() => {
    'name': name,
    'script': script,
    'selected': selected,
  };

  @override
  String toString() {
    return 'UserScript{name: $name, script: $script, selected: $selected}';
  }
}

class UserPreferencesScripts {
  static final UserPreferencesScripts _singleton = UserPreferencesScripts._internal();

  factory UserPreferencesScripts() {
    return _singleton;
  }

  UserPreferencesScripts._internal();

  // Temporary implementation for single script management.
  final userScript = ObservableStringPreference(_UserPreferenceKeys.Script);
  final userScriptEnabled = ObservableBoolPreference(_UserPreferenceKeys.ScriptEnabled);

  /*
  ObservablePreference<List<UserScript>> keys = ObservablePreference(
      key: _UserPreferenceKeys.Scripts,
      getValue: (key) {
        return _getScripts();
      },
      putValue: (key, keys) {
        return _setKeys(keys);
      });

  static List<UserScript> _getScripts() {

    String? value =
    UserPreferences().getStringForKey(_UserPreferenceKeyKeys.Keys);
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
          .whereType<StoredEthereumKey>()
          .toList();
    } catch (err) {
      log("Error retrieving keys!: $value, $err");
      return [];
    }
  }

  static Future<bool> _setKeys(List<StoredEthereumKey>? keys) async {
    print("setKeys: storing keys: ${jsonEncode(keys)}");
    if (keys == null) {
      return UserPreferences()
          .sharedPreferences()
          .remove(_UserPreferenceKeyKeys.Keys.toString());
    }
    try {
      var value = jsonEncode(keys);
      return await UserPreferences()
          .putStringForKey(_UserPreferenceKeyKeys.Keys, value);
    } catch (err) {
      log("Error storing keys!: $err");
      return false;
    }
  }

  /// Remove a key from the user's keystore.
  Future<bool> removeKey(StoredEthereumKeyRef keyRef) async {
    var keysList = ((keys.get()) ?? []);
    try {
      keysList.removeWhere((key) => key.uid == keyRef.keyUid);
    } catch (err) {
      log("account: error removing key: $keyRef");
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
    log("XXX: addKeyIfNeeded: add key if needed: $key");
    var curKeys = keys.get() ?? [];
    if (!curKeys.contains(key)) {
      log("XXX: addKeyIfNeeded: adding key");
      await keys.set(curKeys + [key]);
    } else {
      log("XXX: addKeyIfNeeded: duplicate key");
    }
  }

  /// Add a list of keys to the user's keystore.
  Future<void> addKeys(List<StoredEthereumKey> newKeys) async {
    var allKeys = ((keys.get()) ?? []) + newKeys;
    await keys.set(allKeys);
  }

   */

///
/// End: Keys
///


}

enum _UserPreferenceKeys implements UserPreferenceKey {
  Script,
  ScriptEnabled,
  // Scripts,
}
