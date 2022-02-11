import 'package:orchid/api/configuration/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/js_config.dart';

/// This class supports stored JS configuration from user preferences.
/// See OrchidUserParam for explicit URL parameters in the web context.
/// See UserPreferences() for cross-platform application user data storage.
class OrchidUserConfig {
  static final OrchidUserConfig _shared = OrchidUserConfig._internal();

  OrchidUserConfig._internal();

  factory OrchidUserConfig() {
    return _shared;
  }

  /// Return a JS queryable representation of the user-visible configuration.
  /// On web any supplied user URL parameters are appended and override the
  /// corresponding stored config values.
  /// If there is an error parsing the configuation an empty JSConfig is returned.
  JSConfig getUserConfigJS() {
    try {
      var js = UserPreferences().userConfig.get() ?? '';
      if (OrchidPlatform.isWeb) {
        js += OrchidUserParams().asJS();
      }
      return JSConfig(js);
    } catch (err) {
      print("Error parsing user entered configuration as JS: $err");
    }
    return JSConfig('');
  }
}
