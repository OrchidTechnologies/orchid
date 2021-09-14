import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/pages/app_routes.dart';
import 'package:orchid/pages/side_drawer.dart';
import 'package:orchid/util/on_off.dart';
import 'connect/connect_page.dart';

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
      routes: AppRoutes.routes,
    );
  }
}

class OrchidAppNoTabs extends StatefulWidget {
  @override
  _OrchidAppNoTabsState createState() => _OrchidAppNoTabsState();

  static Widget constrainMaxSize(Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 450, maxHeight: AppSize.iphone_12_pro_max.height),
          child: child),
    );
  }
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
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
            preferredSize: preferredSize,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              brightness: Brightness.dark,
              // status bar
              actions: [_buildTrafficButton()],
            )),
        body: _body(),
        backgroundColor: Colors.transparent,
        drawer: SideDrawer(),
      ),
    );
  }

  Widget _buildTrafficButton() {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.traffic);
      },
      child: SvgPicture.asset('assets/svg/traffic.svg'),
    );
  }

  // Produce the main app body, which at large sizes is constrained and centered at top.
  Widget _body() {
    return OrchidAppNoTabs.constrainMaxSize(ConnectPage());
  }

}
