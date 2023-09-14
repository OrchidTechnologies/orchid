import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/orchid/orchid_desktop_dragscroll.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/pages/dapp_home.dart';

// Provide the MaterialApp wrapper and localization context.
class OrchidApp extends StatefulWidget {
  @override
  State<OrchidApp> createState() => _OrchidAppState();
}

class _OrchidAppState extends State<OrchidApp> {
  @override
  Widget build(BuildContext context) {
    return UserPreferencesUI().languageOverride.builder((languageOverride) {
      if (languageOverride != null) {
        log("XXX: language override = $languageOverride");
      }
      return new MaterialApp(
        title: 'Orchid',
        localizationsDelegates: OrchidLanguage.localizationsDelegates,
        supportedLocales: OrchidLanguage.supportedLocales,
        locale: OrchidLanguage.languageOverrideLocale,
        theme: ThemeData(primarySwatch: Colors.deepPurple),
        debugShowCheckedModeBanner: false,
        // The root widget is created twice?
        onGenerateInitialRoutes: (initialRoute) =>
            [MaterialPageRoute(builder: (_) => OrchidAppNoTabs())],
        onGenerateRoute: (settings) {
          //log('generate route: $settings');
          return MaterialPageRoute(builder: (_) => OrchidAppNoTabs());
        },
        scrollBehavior: OrchidDesktopDragScrollBehavior(),
      );
    });
  }
}

class OrchidAppNoTabs extends StatefulWidget {
  @override
  _OrchidAppNoTabsState createState() => _OrchidAppNoTabsState();
}

class _OrchidAppNoTabsState extends State<OrchidAppNoTabs> {
  @override
  void initState() {
    super.initState();
    // log('XXX: OrchidAppNoTabs init');
  }

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    OrchidLanguage.staticLocale = locale;
    // log("XXX: OrchidAppNoTabs build, locale/staticLocale = ${OrchidLanguage.staticLocale}");
    return Container(
      decoration:
          BoxDecoration(gradient: OrchidGradients.blackGradientBackground),
      child: Scaffold(
        body: _body(),
        // extendBodyBehindAppBar: false,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _body() {
    return Center(child: DappHome());
  }
}
