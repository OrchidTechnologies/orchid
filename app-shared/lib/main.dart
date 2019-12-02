import 'package:flutter/material.dart';
import 'package:orchid/pages/orchid_app.dart';
import 'api/orchid_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  OrchidAPI().logger().write("App Startup");
  OrchidAPI().applicationReady();

  // Force portrait orientation
  // Note: There is a bug causing this to fail on iPad, so we have locked
  // Note: the orientation in the main plist:
  // Note: https://github.com/flutter/flutter/issues/27235
  // Orientation.appDefault().then((_) { runApp(OrchidApp()); });
  runApp(OrchidApp());
}


