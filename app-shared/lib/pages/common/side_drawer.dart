import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/pages/app_colors.dart';
import '../app_text.dart';

/// The application side drawer
class SideDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
            color: AppColors.dark_purple,
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.drawer_gradient_start,
                  AppColors.drawer_gradient_end
                ])),
        child: buildContent(context),
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    return Stack(
      children: <Widget>[
        // The menu items
        Column(
          children: <Widget>[
            // top logo
            DrawerHeader(
              child: Image(image: AssetImage('assets/images/logo.png')),
            ),

            divider(),
            SideDrawerTile(
                title: "Connect",
                imageName: 'assets/images/connect.png',
                onPressed: () {
                  Navigator.pushNamed(context, '/');
                }),
            divider(),
            BalanceSideDrawerTile(
                title: "Balance",
                imageName: 'assets/images/wallet.png',
                onPressed: () {
                  Navigator.pushNamed(context, '/balance');
                }),
            divider(),
            SideDrawerTile(
                title: "Settings",
                imageName: 'assets/images/settings.png',
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                }),
            divider(),
            SideDrawerTile(
                title: "Help",
                imageName: 'assets/images/help.png',
                onPressed: () {
                  Navigator.pushNamed(context, '/help');
                }),
            divider(),
            SideDrawerTile(
                title: "Feedback",
                imageName: 'assets/images/feedback.png',
                onPressed: () {
                  Navigator.pushNamed(context, '/feedback');
                }),
            divider(),
          ],
        )
      ],
    );
  }

  Widget divider() {
    return Divider(
      color: Colors.white.withAlpha((0.12 * 255).toInt()),
      height: 1.0,
    );
  }
}

class SideDrawerTile extends StatelessWidget {
  final String title;
  final String imageName;
  final VoidCallback onPressed;

  const SideDrawerTile({
    @required this.title,
    @required this.imageName,
    @required this.onPressed,
  }) : super();

  @override
  Widget build(BuildContext context) {
    return ListTile(
        contentPadding: EdgeInsets.only(left: 20),
        leading: Image(
            height: 32,
            width: 32,
            fit: BoxFit.fill,
            alignment: Alignment.center,
            color: Colors.white,
            image: AssetImage(imageName)),
        title: Text(title,
            textAlign: TextAlign.left, style: AppText.sideDrawerTitleStyle),
        onTap: onPressed);
  }
}

class BalanceSideDrawerTile extends StatefulWidget {
  final String title;
  final String imageName;
  final VoidCallback onPressed;

  const BalanceSideDrawerTile({
    @required this.title,
    @required this.imageName,
    @required this.onPressed,
  }) : super();

  @override
  _BalanceSideDrawerTileState createState() => _BalanceSideDrawerTileState();
}

class _BalanceSideDrawerTileState extends State<BalanceSideDrawerTile> {
  /// The user's balance in OXT or null if unavailable.
  double _balance;

  @override
  void initState() {
    super.initState();
    // Listen to the funding balance.
    OrchidAPI().budget().balance.listen((balance) {
      //OrchidAPI().logger().write("Balance update: $balance.");
      setState(() {
        this._balance = balance;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        contentPadding: EdgeInsets.only(left: 20),
        leading: Image(
            height: 32,
            width: 32,
            fit: BoxFit.fill,
            alignment: Alignment.center,
            color: Colors.white,
            image: AssetImage(widget.imageName)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.title,
                textAlign: TextAlign.left, style: AppText.sideDrawerTitleStyle),
            Text(
                _balance == null
                    ? "(Setup)"
                    : "${_balance.toStringAsFixed(2)} OXT",
                textAlign: TextAlign.left,
                style: AppText.sideDrawerTitleStyle.copyWith(fontSize: 12, height: 1.2)),
          ],
        ),
        onTap: widget.onPressed);
  }

}
