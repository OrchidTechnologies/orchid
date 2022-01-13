import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/pages/dapp_home.dart';

// Provide the MaterialApp wrapper and localization context.
class OrchidApp extends StatefulWidget {
  @override
  State<OrchidApp> createState() => _OrchidAppState();
}

class _OrchidAppState extends State<OrchidApp> {
  final homePage = OrchidAppNoTabs();

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Orchid',
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: OrchidPlatform.languageOverride == null
          ? S.supportedLocales
          : [
              Locale.fromSubtags(
                  languageCode: OrchidPlatform.languageOverrideCode,
                  countryCode: OrchidPlatform.languageOverrideCountry)
            ],
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      debugShowCheckedModeBanner: false,
      // scrollBehavior: OrchidDesktopDragScrollBehavior(),
      // Without this the root widget is created twice?
      onGenerateInitialRoutes: (initialRoute) =>
          [MaterialPageRoute(builder: (_) => homePage)],
      onGenerateRoute: (settings) {
        //log("generate route: $settings");
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
  void initState() {
    super.initState();
    log("XXX: OrchidAppNoTabs init");
  }

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    OrchidPlatform.staticLocale = locale;
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

