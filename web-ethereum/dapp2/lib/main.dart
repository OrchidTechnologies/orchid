import 'package:orchid/pages/account_manager/account_manager_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OrchidApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Orchid',
      // No localization
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: OrchidPlatform.languageOverride == null
          ? S.supportedLocales
          : [Locale.fromSubtags(languageCode: OrchidPlatform.languageOverride)],
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
  ValueNotifier<Color> _backgroundColor = ValueNotifier(Colors.white);
  ValueNotifier<Color> _iconColor = ValueNotifier(Color(0xFF3A3149));

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async { }

  // If the hop is empty initialize it to defaults now.
  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    OrchidPlatform.staticLocale = locale;
    var preferredSize = Size.fromHeight(kToolbarHeight);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: preferredSize,
        child: AnimatedBuilder(
            animation: Listenable.merge([_backgroundColor, _iconColor]),
            builder: (context, snapshot) {
              return AppBar(
                  backgroundColor: _backgroundColor.value,
                  elevation: 0,
                  iconTheme: IconThemeData(color: _iconColor.value),
                  brightness: Brightness.light // status bar
              );
            }),
      ),
      body: _body(),
      backgroundColor: Colors.white,
    );
  }

  Widget _body() {
    return Center(
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: AccountManagerPage()),
    );
  }
}

void main() {
  runApp(OrchidApp());
}

