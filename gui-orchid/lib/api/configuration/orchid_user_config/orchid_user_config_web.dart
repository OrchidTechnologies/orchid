import 'dart:async';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/js_config.dart';
import 'orchid_user_config.dart';

// TODO: We should unify the url parameter config with this for web.
class OrchidUserConfigImpl implements OrchidUserConfig {
  Future<JSConfig> getUserConfigJS() async {
    try {
      return JSConfig(await UserPreferences().userConfig.get());
    } catch (err) {
      print("Error parsing user entered configuration as JS: $err");
    }
    return JSConfig("");
  }
}
