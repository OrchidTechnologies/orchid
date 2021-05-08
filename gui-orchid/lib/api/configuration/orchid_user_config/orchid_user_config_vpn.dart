import 'dart:async';
import 'package:orchid/util/js_config.dart';
import '../../orchid_api.dart';
import 'orchid_user_config.dart';

class OrchidUserConfigImpl implements OrchidUserConfig {
  Future<JSConfig> getUserConfigJS() async {
    try {
      return JSConfig(await OrchidAPI().getConfiguration());
    } catch (err) {
      print("Error parsing user entered configuration as JS: $err");
    }
    return JSConfig("");
  }
}
