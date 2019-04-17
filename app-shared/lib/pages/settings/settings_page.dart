import 'package:flutter/material.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

class SettingsPage extends TitledPageBase {
  SettingsPage() : super(title: "Settings");

  Widget buildPage(BuildContext context) {
    return Column(
      children: <Widget>[
        PageTile.route(
            title: "Wallet",
            imageName: "assets/images/account_balance_wallet.png",
            routeName: '/settings/wallet',
            context: context),
        PageTile.route(
            title: "Log",
            imageName: "assets/images/assignment.png",
            routeName: '/settings/log',
            context: context),
        PageTile.route(
            title: "VPN credentials",
            imageName: "assets/images/business.png",
            routeName: '/settings/vpn',
            context: context),
        PageTile.route(
            title: "Developer",
            imageName: "assets/images/settings.png",
            routeName: '/settings/dev',
            context: context),
      ],
    );
  }
}
