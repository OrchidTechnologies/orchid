import 'package:flutter/material.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/purchase/orchid_purchase.dart';
import 'package:orchid/pages/orchid_app.dart';
import 'package:window_size/window_size.dart';
import 'api/configuration/orchid_user_config/orchid_user_config.dart';
import 'api/monitoring/routing_status.dart';
import 'api/orchid_api.dart';
import 'api/orchid_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences.init();
  OrchidAPI().logger().write("App Startup");
  OrchidRoutingStatus().beginPollingStatus();
  OrchidAPI().applicationReady();
  OrchidPlatform.pretendToBeAndroid =
      (await OrchidUserConfig().getUserConfigJS())
          .evalBoolDefault('isAndroid', false);
  if (OrchidPlatform.isApple || OrchidPlatform.isAndroid) {
    OrchidPurchaseAPI().initStoreListener();
  }
  var languageOverride =
      (const String.fromEnvironment('language', defaultValue: null)) ??
          (await OrchidUserConfig().getUserConfigJS())
              .evalStringDefault("lang", null);
  if (languageOverride != null &&
      OrchidPlatform.hasLanguage(languageOverride)) {
    OrchidPlatform.languageOverride = languageOverride;
  }
  if (OrchidPlatform.isMacOS) {
    print("main: Setting window size");
    setWindowFrame(Rect.fromLTWH(100, 100, 414, 890));
    setWindowMinSize(Size(216, 250));
  }

  runApp(OrchidApp());
}
