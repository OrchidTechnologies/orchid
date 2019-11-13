import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orchid/api/monitoring/analysis_db.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/util/units.dart';
import '../app_routes.dart';
import '../app_text.dart';
import 'dialogs.dart';

/// The application side drawer
class SideDrawer extends StatefulWidget {
  @override
  _SideDrawerState createState() => _SideDrawerState();
}

class _SideDrawerState extends State<SideDrawer> {
  String _version;

  @override
  void initState() {
    super.initState();
    OrchidAPI().versionString().then((value) {
      debugPrint("got version: $value");
      setState(() {
        _version = value;
      });
    });
  }

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
    return Column(
      children: <Widget>[
        // top logo
        DrawerHeader(
          child: Image(image: AssetImage('assets/images/logo.png')),
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              Visibility(
                visible: OrchidBudgetAPI.featureEnabled,
                child: Column(
                  children: <Widget>[
                    BalanceSideDrawerTile(
                        title: "Balance",
                        imageName: 'assets/images/wallet.png',
                        onPressed: () {
                          //Navigator.pushNamed(context, '/budget/balance');
                        }),
                    divider(),
                  ],
                ),
              ),
              /*
              SideDrawerTile(
                  title: "Copy Signer Key",
                  imageName: 'assets/images/fileDocumentOutline.png',
                  onPressed: () {
                    _copySignerKey(context);
                  }),
               */
              SideDrawerTile(
                  title: "Key Generator",
                  imageName: 'assets/images/fileDocumentOutline.png',
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings/keygen');
                  }),
              divider(),
              SideDrawerTile(
                  title: "Clear Data",
                  icon: Icons.delete_forever,
                  onPressed: () {
                    _confirmDelete(context);
                  }),
              divider(),
              SideDrawerTile(
                  title: "Help",
                  //imageName: 'assets/images/help.png',
                  icon: Icons.help_outline,
                  showDetail: true,
                  onPressed: () {
                    Navigator.pushNamed(context, '/help/overview');
                  }),
              divider(),
              SideDrawerTile(
                  title: "Privacy Policy",
                  imageName: 'assets/images/fileDocumentOutline.png',
                  showDetail: true,
                  hoffset: 4.0,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.privacy);
                  }),

              divider(),
              SideDrawerTile(
                  title: "Open Source Licenses",
                  imageName: 'assets/images/fileDocumentBoxMultipleOutline.png',
                  showDetail: true,
                  hoffset: 4.0,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.open_source);
                  }),

              divider(),
              SideDrawerTile(
                  title: "Configuration",
                  imageName: 'assets/images/settings.png',
                  showDetail: true,
                  hoffset: 4.0,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.configuration);
                  }),

            ],
          ),
        ),

        // Version info at the bottom
        SafeArea(
          child: Column(
            children: <Widget>[
              divider(),
              SizedBox(height: 16),
              Text("Version: " + (_version ?? ""),
                  style:
                      AppText.noteStyle.copyWith(color: AppColors.neutral_4)),
            ],
          ),
        )
      ],
    );
  }

  /*
  void _copySignerKey(BuildContext context) async {
    var signerKey = await OrchidAPI().budget().getSignerKey();
    Clipboard.setData(ClipboardData(text: signerKey));
    Dialogs.showAppDialog(
        context: context,
        title: "Signer Key Copied",
        body: "Your public signer key has been copied to the clipboard.  "
            +"Paste this into the Create Account screen of the Orchid Account Manager Dapp to link "
           + "this client to your account.",
        );
  }*/

  void _confirmDelete(BuildContext context) {
    Dialogs.showConfirmationDialog(
        context: context,
        title: "Delete all data?",
        body: "This will delete all recorded data within the app.",
        cancelText: "CANCEL",
        actionText: "OK",
        action: () async {
          await AnalysisDb().clear();
        });
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
  final IconData icon;
  final VoidCallback onPressed;
  final bool showDetail;
  final double hoffset;

  SideDrawerTile(
      {@required this.title,
      this.imageName,
      this.icon,
      @required this.onPressed,
      this.showDetail = false,
      this.hoffset = 0})
      : super() {
    assert(imageName != null || icon != null);
  }

  @override
  Widget build(BuildContext context) {
    Widget leading = imageName != null
        ? Image(
            height: 24,
            width: 24,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            color: Colors.white,
            image: AssetImage(imageName))
        : Icon(icon, color: Colors.white, size: 32);
    return ListTile(
        contentPadding: EdgeInsets.only(left: 20, right: 20),
        leading: Padding(
          padding: EdgeInsets.only(left: hoffset),
          child: leading,
        ),
        trailing: showDetail
            ? Icon(Icons.chevron_right, color: AppColors.white)
            : null,
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
  OXT _balance;
  StreamSubscription _balanceListener;

  @override
  void initState() {
    super.initState();

    if (OrchidBudgetAPI.featureEnabled) {
      // Listen to the funding balance.
      _balanceListener = OrchidAPI().budget().potStatus.listen((pot) {
        setState(() {
          this._balance = pot.balance;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        contentPadding: EdgeInsets.only(left: 20, right: 20),
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
                    : "${_balance.value.toStringAsFixed(2)} OXT",
                textAlign: TextAlign.left,
                style: AppText.sideDrawerTitleStyle
                    .copyWith(fontSize: 12, height: 1.2)),
          ],
        ),
        //trailing: Icon(Icons.chevron_right, color: AppColors.white),
        onTap: widget.onPressed);
  }

  @override
  void dispose() {
    super.dispose();
    _balanceListener.cancel();
  }


}
