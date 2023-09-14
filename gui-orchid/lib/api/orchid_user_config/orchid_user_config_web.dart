import 'package:orchid/api/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/util/user_config.dart';

class UserConfigImpl {
  static UserConfig getUserConfig() {
    return MapUserConfig(OrchidUserParams().params);
  }
}
