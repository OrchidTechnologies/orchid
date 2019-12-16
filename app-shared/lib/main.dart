import 'package:flutter/material.dart';
import 'package:orchid/pages/orchid_app.dart';
import 'api/orchid_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  OrchidAPI().logger().write("App Startup");
  OrchidAPI().applicationReady();
  runApp(OrchidAppTabbed());
}
