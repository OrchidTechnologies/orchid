import 'package:flutter/material.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_colors.dart';
import '../orchid_app.dart';

/// The main settings page.
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _defaultCurator = TextEditingController();
  //bool _queryBalances = false;
  bool _showStatusTab = false;

  @override
  void initState() {
    super.initState();
    initStateAsync();
    _defaultCurator.addListener(_curatorChanged);
  }

  void initStateAsync() async {
    //_queryBalances = await UserPreferences().getQueryBalances();
    _defaultCurator.text = await UserPreferences().getDefaultCurator() ??
        OrchidHop.appDefaultCurator;
    _showStatusTab = await UserPreferences().getShowStatusTab();
    setState(() { });
  }

  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    return TitledPage(
      title: "Settings",
      child: Column(
        children: <Widget>[
          /*
          PageTile.route(
              title: "Log",
              imageName: "assets/images/assignment.png",
              routeName: '/settings/log',
              context: context),
           */
          /* TODO:
          PageTile(
            title: "Query Address",
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
          Divider(),
           */
          // Default curator
          pady(16),
          PageTile(
            title: "Default Curator",
            //imageName: "assets/images/assignment.png",
            trailing: Container(
                width: screenWidth * 0.5,
                child: AppTextField(
                    controller: _defaultCurator, margin: EdgeInsets.zero)),
          ),
          // Show status page
          pady(16),
          Divider(),
          PageTile(
            title: "Show Status Page (beta)",
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
          pady(8),
          Divider(),
          pady(8),
          PageTile(
            title: "Show Instructions",
            trailing: RaisedButton(
              child: Text("Reset"),
              onPressed: () {
                UserPreferences().setVPNSwitchInstructionsViewed(false);
              },
            ),
          ),
          pady(16),
          Divider(),
        ],
      ),
    );
  }

  void _curatorChanged() {
    UserPreferences().setDefaultCurator(_defaultCurator.text);
  }

  @override
  void dispose() {
    super.dispose();
    _defaultCurator.removeListener(_curatorChanged);
  }
}
