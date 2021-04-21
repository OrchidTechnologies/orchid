import 'dart:async';
import 'package:orchid/util/js_config.dart';
import 'orchid_user_config.dart';

// TODO: We unify the url parameter config with this for web.
class OrchidUserConfigImpl implements OrchidUserConfig {
  Future<JSConfig> getUserConfigJS() async {
    return JSConfig("");
  }
}
