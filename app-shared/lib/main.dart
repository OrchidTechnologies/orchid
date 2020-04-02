import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_purchase.dart';
import 'package:orchid/pages/orchid_app.dart';
import 'api/orchid_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  OrchidAPI().logger().write("App Startup");
  OrchidAPI().applicationReady();
  if (Platform.isIOS || Platform.isAndroid) {
    OrchidPurchaseAPI().initStoreListener();
  }
  runApp(OrchidApp());
}
