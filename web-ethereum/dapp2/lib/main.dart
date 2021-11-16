import 'package:flutter/material.dart';
import 'package:orchid/pages/orchid_app.dart';
import 'api/preferences/user_preferences.dart';

void main() async {
  await UserPreferences.init();
  runApp(OrchidApp());
}
