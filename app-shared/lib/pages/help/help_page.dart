import 'package:flutter/material.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class HelpPage extends TitledPageBase {
  HelpPage() : super(title: "Help");

  Widget buildPage(BuildContext context) {
    return Column(
      children: <Widget>[
        PageTile.route(
            title: "Linking your wallet",
            routeName: '/help/link_wallet',
            context: context),
        PageTile.route(
            title: "Choosing a server",
            routeName: '/help/choose_server',
            context: context),
        PageTile.route(
            title: "Adding a server",
            routeName: '/settings/add_server',
            context: context),
        PageTile.route(
            title: "Problems connecting",
            routeName: '/settings/problems_connecting',
            context: context),
      ],
    );
  }
}
