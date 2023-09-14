import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/vpn/orchid_vpn_config/js_config.dart';
import 'package:orchid/util/user_config.dart';

class UserConfigImpl {
  static UserConfig getUserConfig() {
    try {
      var js = UserPreferencesUI().userConfig.get() ?? '';
      return JSConfig(js);
    } catch (err) {
      print("Error parsing user entered configuration as JS: $err");
    }
    return JSConfig('');
  }
}
