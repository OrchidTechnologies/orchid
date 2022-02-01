import 'package:flutter/material.dart';
import 'package:orchid/pages/orchid_app.dart';
import 'api/orchid_platform.dart';
import 'api/preferences/user_preferences.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Main for the Orchid account management dapp.
void main() async {
  // Turn off the default fragment path strategy for web.
  setUrlStrategy(PathUrlStrategy());
  await UserPreferences.init();
  OrchidPlatform.initLanguageOverride();
  runApp(OrchidApp());
}
