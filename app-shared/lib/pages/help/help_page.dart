import 'package:flutter/material.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class HelpPage extends TitledPageBase {
  HelpPage() : super(title: "Help");

  Widget buildPage(BuildContext context) {
    return Column(
      children: <Widget>[
        PageTile.route(
            title: "Overview",
            //imageName: "assets/images/account_balance_wallet.png",
            routeName: '/help/overview',
            context: context),
        PageTile.route(
            title: "Privacy Policy",
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
}
