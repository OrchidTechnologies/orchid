import 'package:flutter/material.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/circuit/circuit_hop.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_colors.dart';

/// The main settings page.
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _defaultCurator = TextEditingController();

  @override
  void initState() {
    super.initState();
    initStateAsync();
    _defaultCurator.addListener(_curatorChanged);
  }

  void initStateAsync() async {
    _defaultCurator.text = await UserPreferences().getDefaultCurator() ??
        OrchidHop.appDefaultCurator;
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
          PageTile(
            title: "Query Balances",
            //imageName: "assets/images/assignment.png",
            trailing: Switch(
              activeColor: AppColors.purple_3,
              value: false,
              onChanged: null/*(bool value) {}*/,
            ),
          ),
          Divider(),
          PageTile(
            title: "Default Curator",
            //imageName: "assets/images/assignment.png",
            trailing: Container(
                width: screenWidth * 0.5,
                child: AppTextField(
                    controller: _defaultCurator, margin: EdgeInsets.zero)),
          )
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
