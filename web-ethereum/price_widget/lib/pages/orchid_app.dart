import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/orchid/orchid_gradients.dart';

import 'orchid_widget_home.dart';

// Provide the MaterialApp wrapper and localization context.
class OrchidApp extends StatefulWidget {
  @override
  State<OrchidApp> createState() => _OrchidAppState();
}

class _OrchidAppState extends State<OrchidApp> {
  final homePage = OrchidAppNoTabs();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orchid',
      localizationsDelegates: OrchidLanguage.localizationsDelegates,
      supportedLocales: OrchidLanguage.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      debugShowCheckedModeBanner: false,
      // Without this the root widget is created twice?
      onGenerateInitialRoutes: (initialRoute) {
        log('XXX: initialRoute: $initialRoute');
        return [MaterialPageRoute(builder: (_) => homePage)];
      },
      onGenerateRoute: (settings) {
        log('XXX: generate route: $settings');
        return MaterialPageRoute(builder: (_) => homePage);
      },
    );
  }
}

class OrchidAppNoTabs extends StatefulWidget {
  @override
  _OrchidAppNoTabsState createState() => _OrchidAppNoTabsState();
}

class _OrchidAppNoTabsState extends State<OrchidAppNoTabs> {

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    OrchidLanguage.staticLocale = locale;
    final color = OrchidUserParams().getColor('background_color');
    return Container(
      color: color,
      decoration: color == null ? BoxDecoration(
          gradient: OrchidGradients.blackGradientBackground) : null,
      child: Scaffold(
        body: _body(),
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _body() {
    return Center(child: OrchidWidgetHome());
  }
}

