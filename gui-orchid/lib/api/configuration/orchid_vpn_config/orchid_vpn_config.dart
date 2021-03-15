import 'dart:async';

import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v1.dart';
import 'package:orchid/api/preferences/user_preferences.dart';

import '../../orchid_api.dart';
import '../js_config.dart';

class OrchidVPNConfig {
  /// Return a JS queryable representation of the user visible configuration
  /// If there is an error parsing the configuation an empty JSConfig is returned.
  static Future<JSConfig> getUserConfigJS() async {
    try {
      return JSConfig(await OrchidAPI().getConfiguration());
    } catch (err) {
      print("Error parsing user entered configuration as JS: $err");
    }
    return JSConfig("");
  }

  static Future<String> generateConfig() async {
    return (await UserPreferences().guiV0.get())
        ? OrchidVPNConfigV0.generateConfig()
        : OrchidVPNConfigV1.generateConfig();
  }
}
