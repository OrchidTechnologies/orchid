import 'package:orchid/api/orchid_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  /// The shared instance, initialized by init()
  static SharedPreferences? _sharedPreferences;

  static bool get initialized {
    return _sharedPreferences != null;
  }

  /// This should be awaited during app launch.
  static Future<void> init() async {
    if (!initialized) {
      _sharedPreferences = await SharedPreferences.getInstance();
      log("Initialized user preferences API");
    }
  }

  SharedPreferences sharedPreferences() {
    if (!initialized) {
      throw Exception("UserPreferences uninitialized.");
    }
    return _sharedPreferences!;
  }

  // Match legacy usage
  String _keyToLookupString(UserPreferenceKey key) {
    return 'UserPreferenceKey.' + key.name;
  }

  String? getStringForKey(UserPreferenceKey key) {
    var keyString = _keyToLookupString(key);
    return sharedPreferences().getString(keyString);
  }

  // This method maps null to property removal.
  Future<bool> putStringForKey(UserPreferenceKey key, String? value) async {
    var keyString = _keyToLookupString(key);
    var shared = sharedPreferences();
    if (value == null) {
      return await shared.remove(keyString);
    }
    return await shared.setString(keyString, value);
  }
}

/// Should be implemented by enums of user preference keys.
abstract class UserPreferenceKey implements Enum {}
