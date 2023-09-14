import 'package:orchid/util/user_config.dart';

// Conditionally import the JS implementation on mobile
import 'orchid_user_config_vpn.dart'
    if (dart.library.html) 'orchid_user_config_web.dart';

/// This class supports stored JS configuration from user preferences.
/// See OrchidUserParam for explicit URL parameters in the web context.
/// See UserPreferences() for cross-platform application user data storage.
class OrchidUserConfig {
  static final OrchidUserConfig _shared = OrchidUserConfig._internal();

  OrchidUserConfig._internal();

  factory OrchidUserConfig() {
    return _shared;
  }

  UserConfig getUserConfig() {
    return UserConfigImpl.getUserConfig();
  }

  static bool get isTester {
    var jsConfig = OrchidUserConfig().getUserConfig();
    return jsConfig.evalBoolDefault('tester', false);
  }
}
