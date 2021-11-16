import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/pages/dapp_home.dart';

// Provide the MaterialApp wrapper and localization context.
class OrchidApp extends StatelessWidget {
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
      home: OrchidAppNoTabs(),
      debugShowCheckedModeBanner: false,
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
    return Center(
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600), child: DappHome()),
    );
  }
}
