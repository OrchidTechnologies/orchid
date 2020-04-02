import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class LegalPage extends StatefulWidget {
  @override
  _LegalPageState createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "Legal", child: buildPage(context));
  }

  Widget buildPage(BuildContext context) {
    return Column(
      children: <Widget>[
        PageTile.route(
            title: s.privacyPolicy,
            //imageName: "assets/images/account_balance_wallet.png",
            routeName: '/help/privacy',
            context: context),
        PageTile.route(
            title: "Open Source Licenses",
            //imageName: "assets/images/assignment.png",
            routeName: '/help/open_source',
            context: context),
      ],
    );
  }

  S get s {
    return S.of(context);
  }
}
