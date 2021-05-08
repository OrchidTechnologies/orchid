import 'dart:async';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v1.dart';
import 'package:orchid/api/preferences/user_preferences.dart';

class OrchidVPNConfig {
  static Future<String> generateConfig() async {
    return (await UserPreferences().guiV0.get())
        ? OrchidVPNConfigV0.generateConfig()
        : OrchidVPNConfigV1.generateConfig();
  }
}
