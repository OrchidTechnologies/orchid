import 'package:orchid/util/js_config.dart';
import 'orchid_user_config_stub.dart'
    if (dart.library.io) 'orchid_user_config_vpn.dart'
    if (dart.library.js) 'orchid_user_config_web.dart';

// This class supports the alternate implementations for advanced user
// configuration on the main platforms and web.
abstract class OrchidUserConfig {
  static OrchidUserConfig _shared = OrchidUserConfigImpl();

  factory OrchidUserConfig() {
    return _shared;
  }

  /// Return a JS queryable representation of the user-visible configuration
  /// If there is an error parsing the configuation an empty JSConfig is returned.
  JSConfig getUserConfigJS();
}
