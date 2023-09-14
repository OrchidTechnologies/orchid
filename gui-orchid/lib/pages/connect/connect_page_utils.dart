import 'package:orchid/vpn/orchid_api_mock.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/pages/app_routes.dart';
import 'package:orchid/pages/purchase/purchase_page.dart';

class ConnectPageUtils {
  /// Check for startup args. e.g. for screenshot rigging.
  static void checkStartupCommandArgs(BuildContext context) async {
    log("Check command args");

// TODO: This should be updated to import a circuit config.
// Allow setting the account for screenshots
// Must use 'const' here:  https://github.com/flutter/flutter/issues/55870
/*
    const identity = String.fromEnvironment('identity', defaultValue: null);
    if (identity != null) {
      try {
        setDefaultIdentityFromString(identity);
      } catch (err) {
        log("Error setting default identity from string: $err");
      }
    }
     */

// Set connected status
    const connected = bool.fromEnvironment('connected', defaultValue: false);
    if (connected) {
      MockOrchidAPI.fakeVPNDelay = 0;
      UserPreferencesVPN().routingEnabled.set(connected);
    }

// Push to named screen
    const showScreen = String.fromEnvironment('screen');
    if (showScreen == 'accounts') {
      await Navigator.pushNamed(context, AppRoutes.account_manager);
    } else if (showScreen == 'purchase') {
      Navigator.push(
          context,
          MaterialPageRoute(
              fullscreenDialog: true,
              builder: (BuildContext context) {
                return PurchasePage(
                    signerKey: null,
                    cancellable: true,
                    completion: () {
                      log("purchase complete");
                    });
              }));
    } else if (showScreen == 'traffic') {
      await UserPreferencesVPN().monitoringEnabled.set(true);
      await Navigator.pushNamed(context, AppRoutes.traffic);
    } else if (showScreen == 'circuit') {
      await Navigator.pushNamed(context, AppRoutes.circuit);
    }
  }
}
