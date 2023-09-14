import 'package:flutter/material.dart';
import 'package:orchid/pages/orchid_app.dart';
import 'api/preferences/user_preferences.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'api/pricing/orchid_pricing.dart';

/// Main for the Orchid account management dapp.
void main() async {
  // Turn off the default fragment path strategy for web.
  setUrlStrategy(PathUrlStrategy());
  await UserPreferences.init();
  runApp(OrchidApp());

  OrchidPricing.logTokenPrices();
}
