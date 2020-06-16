import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/js_config.dart';
import 'package:orchid/api/configuration/orchid_vpn_config.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/page_tile.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/pages/common/titled_page_base.dart';

import '../app_colors.dart';
import '../app_sizes.dart';
import '../orchid_app.dart';

/// The main settings page.
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _defaultCurator = TextEditingController();

  bool _queryBalances = false;
  bool _allowNoHopVPN = false;
  bool _showLogging = false;

  @override
  void initState() {
    super.initState();
    ScreenOrientation.all();
    initStateAsync();
    _defaultCurator.addListener(_curatorChanged);
  }

  void initStateAsync() async {
    _queryBalances = await UserPreferences().getQueryBalances();
    _defaultCurator.text = await UserPreferences().getDefaultCurator() ??
        OrchidHop.appDefaultCurator;
    _allowNoHopVPN = await UserPreferences().getAllowNoHopVPN();
    setLoggingConfig();
    setState(() {});
  }

  void setLoggingConfig() async {
    var jsConfig = await OrchidVPNConfig.getUserConfigJS();
    _showLogging = jsConfig.evalBoolDefault('logging', false);
  }

  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    return TitledPage(
      title: s.settings,
      decoration: BoxDecoration(),
      child: Padding(
        padding: EdgeInsets.all(
            AppSize(context).tallerThan(AppSize.iphone_xs_max) ? 128 : 0),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: <Widget>[
                // Default curator
                pady(16),
                PageTile(
                  title: s.defaultCurator,
                  //imageName: "assets/images/assignment.png",
                  trailing: Container(
                      width: screenWidth * 0.5,
                      child: AppTextField(
                          controller: _defaultCurator,
                          margin: EdgeInsets.zero)),
                ),
                pady(8),

                // Allow enable vpn with no hops
                pady(16),
                Divider(),
                PageTile(
                  title:
                      s.allowNoHopVPN + "\n(" + s.trafficMonitoringOnly + ")",
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
                /*
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
                 */

                // Advanced Configuration
                pady(8),
                Divider(),
                PageTile(
                  title: "Advanced Configuration",
                  onTap: () async {
                    await Navigator.pushNamed(
                        context, '/settings/configuration');
                    initStateAsync(); // update anything that may have changed via config
                  },
                ),

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

                // Logging
                if (_showLogging) ...[
                  pady(16),
                  PageTile.route(
                      title: "Logging",
                      routeName: '/settings/log',
                      context: context),
                ],

                pady(32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetInstructions() async {
    UserPreferences().resetInstructions();
    Dialogs.showAppDialog(
        context: context,
        title: "Reset",
        bodyText:
            "Help instructions will be shown again in appropriate places.");
  }

  void _curatorChanged() {
    UserPreferences().setDefaultCurator(_defaultCurator.text);
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    _defaultCurator.removeListener(_curatorChanged);
  }

  S get s {
    return S.of(context);
  }
}
