import 'package:orchid/api/orchid_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension SharedPreferencesUtil on SharedPreferences {
  static Future<Map<String, Object>> dump() async {
    var prefs = await SharedPreferences.getInstance();
    var keys = prefs.getKeys();
    Map<String, Object> map = {};
    for (var key in keys) {
      var value = prefs.get(key);
      log("XXX: key = $key, type = ${value.runtimeType}, value = $value");
      if (value != null) {
        map[key] = value;
      }
    }
    return map;
  }
}
