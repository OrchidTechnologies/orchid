import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/vpn/purchase/orchid_purchase.dart';
import 'orchid/orchid.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/orchid_app.dart';
import 'package:window_size/window_size.dart';
import 'api/orchid_user_config/orchid_user_config.dart';
import 'vpn/monitoring/routing_status.dart';
import 'api/orchid_platform.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences.init();
  log("App Startup");
  FlutterError.onError = (FlutterErrorDetails details) {
    print("FlutterError:  ${details.exception}");
    print("FlutterError:  ${details.stack}");
  };
  OrchidRoutingStatus().beginPollingStatus();
  OrchidAPI().applicationReady();
  OrchidPlatform.pretendToBeAndroid =
      OrchidUserConfig().getUserConfig().evalBoolDefault('isAndroid', false);
  if (OrchidPlatform.isApple || OrchidPlatform.isAndroid) {
    OrchidPurchaseAPI().initStoreListener();
  }
  if (OrchidPlatform.isMacOS) {
    print("main: Setting window size");
    setWindowFrame(Rect.fromLTWH(100, 100, 414, 890));
    setWindowMinSize(Size(216, 250));
  }

  runApp(OrchidApp());
  // OrchidPricing.logTokenPrices();
}
