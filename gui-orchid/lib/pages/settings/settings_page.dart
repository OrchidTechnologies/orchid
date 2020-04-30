import 'package:flutter/material.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/purchase/purchase_page.dart';

import '../app_colors.dart';
import '../orchid_app.dart';

/// The main settings page.
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _defaultCurator = TextEditingController();

  bool _queryBalances = false;
  bool _showStatusTab = false;
  bool _allowNoHopVPN = false;

  @override
  void initState() {
    super.initState();
    initStateAsync();
    _defaultCurator.addListener(_curatorChanged);
  }

  void initStateAsync() async {
    _queryBalances = await UserPreferences().getQueryBalances();
    _defaultCurator.text = await UserPreferences().getDefaultCurator() ??
        OrchidHop.appDefaultCurator;
    _showStatusTab = await UserPreferences().getShowStatusTab();
    _allowNoHopVPN = await UserPreferences().getAllowNoHopVPN();
    setState(() {});
  }

  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return TitledPage(
      title: s.settings,
      child: Column(
        children: <Widget>[
          /*
          PageTile.route(
              title: "Log",
              imageName: "assets/images/assignment.png",
              routeName: '/settings/log',
              context: context),
           */
          // Default curator
          pady(16),
          PageTile(
            title: s.defaultCurator,
            //imageName: "assets/images/assignment.png",
            trailing: Container(
                width: screenWidth * 0.5,
                child: AppTextField(
                    controller: _defaultCurator, margin: EdgeInsets.zero)),
          ),
          pady(8),

          // Allow enable vpn with no hops
          pady(16),
          Divider(),
          PageTile(
            title: s.allowNoHopVPN + "\n(" + s.trafficMonitoringOnly + ")",
            trailing: Switch(
              activeColor: AppColors.purple_3,
              value: _allowNoHopVPN,
              onChanged: (bool value) {
                UserPreferences().setAllowNoHopVPN(value);
                setState(() {
                  _allowNoHopVPN = value;
                });
              },
            ),
          ),

          // Balance query
          pady(8),
          Divider(),
          PageTile(
            title: s.queryBalances,
            //imageName: "assets/images/assignment.png",
            trailing: Switch(
              activeColor: AppColors.purple_3,
              value: _queryBalances,
              onChanged: (bool value) {
                UserPreferences().setQueryBalances(value);
                setState(() {
                  _queryBalances = value;
                });
              },
            ),
          ),

          // Status page
          pady(8),
          PageTile(
            title: s.showStatusPage,
            //imageName: "assets/images/assignment.png",
            trailing: Switch(
              activeColor: AppColors.purple_3,
              value: _showStatusTab,
              onChanged: (bool value) {
                UserPreferences().setShowStatusTab(value);
                setState(() {
                  _showStatusTab = value;
                });
                OrchidAppTabbed.showStatusTabPref.notifyListeners();
              },
            ),
          ),

          // Advanced Configuration
          pady(8),
          Divider(),
          PageTile.route(
              title: "Advanced Configuration",
              routeName: '/settings/configuration',
              context: context),

          // Manage Data
          pady(8),
          Divider(),
          PageTile.route(
              title: "Configuration Management",
              routeName: '/settings/manage_config',
              context: context),

          // Reset instructions
          pady(8),
          Divider(),
          PageTile(
            title: s.showInstructions,
            trailing: RaisedButton(
              child: Text(s.reset),
              onPressed: _resetInstructions,
            ),
          ),
        ],
      ),
    );
  }

  void _resetInstructions() async {
    UserPreferences().resetInstructions();
    Dialogs.showAppDialog(
        context: context,
        title: "Reset",
        bodyText: "Help instructions will be shown again in appropriate places.");
  }

  void _curatorChanged() {
    UserPreferences().setDefaultCurator(_defaultCurator.text);
  }

  @override
  void dispose() {
    super.dispose();
    _defaultCurator.removeListener(_curatorChanged);
  }

  S get s {
    return S.of(context);
  }
}
