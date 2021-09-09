import 'package:flutter/material.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/*
  e.g.
  import 'package:flutter/material.dart';
  import 'package:orchid/util/test_app.dart';
  void main() {
    runApp(TestApp(content: _Test()));
  }
 */
class TestApp extends StatelessWidget {
  final Widget content;
  final double scale;

  const TestApp({
    Key key,
    @required this.content,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: Material(
          child: Container(
        decoration:
            BoxDecoration(gradient: OrchidGradients.blackGradientBackground),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Transform.scale(scale: scale, child: content),
        ),
      )),
    );
  }
}
