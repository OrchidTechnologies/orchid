import 'dart:ui';

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

  // @override
  // void initState() {
  //   super.initState();
  // }

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
      scrollBehavior: DragScrollBehavior(),
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
    initStateAsync();
  }

  void initStateAsync() async {}

  // If the hop is empty initialize it to defaults now.
  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    OrchidPlatform.staticLocale = locale;
    log("locale = $locale");
    var preferredSize = Size.fromHeight(kToolbarHeight);
    return Container(
      decoration:
          BoxDecoration(gradient: OrchidGradients.blackGradientBackground),
      child: Scaffold(
        /*
        appBar: PreferredSize(
            preferredSize: preferredSize,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
            )),
         */
        body: _body(),
        // extendBodyBehindAppBar: false,
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _body() {
    return Center(child: DappHome());
    // return Center(
    //   child: ConstrainedBox(
    //       constraints: BoxConstraints(maxWidth: 600), child: DappHome()),
    // );
  }
}

// The default scroll behavior on desktop (with a mouse) does not support dragging.
class DragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
      };
}
