import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/page_tile.dart';
import 'package:orchid/common/titled_page_base.dart';

class LegalPage extends StatefulWidget {
  @override
  _LegalPageState createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(title: s.legal, child: buildPage(context));
  }

  Widget buildPage(BuildContext context) {
    return Column(
      children: <Widget>[
        PageTile.route(
            title: s.privacyPolicy,
            routeName: '/help/privacy',
            context: context),
        PageTile.route(
            title: s.openSourceLicenses,
            routeName: '/help/open_source',
            context: context),
      ],
    );
  }

  S get s {
    return S.of(context);
  }
}
