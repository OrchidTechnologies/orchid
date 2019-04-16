import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/pages/app_routes.dart';
import 'package:orchid/api/log_file.dart';

void main() {
  // Prime the logging.
  LogFile();

  // Force portrait orientation
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(OrchidApp());
  });
}

class OrchidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Orchid',

        // Theme (overridden for most widgets)
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),

        // Routing
        initialRoute: '/',
        routes: AppRoutes.routes);
  }
}
