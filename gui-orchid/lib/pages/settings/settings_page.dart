import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_platform.dart';
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
import '../app_routes.dart';
import '../app_sizes.dart';

/// The main settings page.
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _defaultCurator = TextEditingController();

  // TODO: These switches should work directly with ObservablePreference
  bool _queryBalances = false;
  bool _allowNoHopVPN = false;
  bool _showLogging = false;
  bool _guiV1 = false;

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
    _allowNoHopVPN = await UserPreferences().allowNoHopVPN.get();
    _guiV1 = await UserPreferences().guiV1.get();
    setLoggingConfig();
    setPlatformConfig();
    setState(() {});
  }

  void setPlatformConfig() async {
    OrchidPlatform.pretendToBeAndroid =
        (await OrchidVPNConfig.getUserConfigJS())
            .evalBoolDefault('isAndroid', false);
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
            AppSize(context).tallerThan(AppSize.iphone_12_max) ? 128 : 0),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Accounts
                pady(16),
                Divider(),
                PageTile(
                  title: s.deletedHops,
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRoutes.accounts);
                  },
                ),

                // Default curator
                pady(8),
                Divider(),
                PageTile(
                  title: s.defaultCurator,
                  //imageName: "assets/images/assignment.png",
                  trailing: Container(
                      width: screenWidth * 0.5,
                      child: AppTextField(
                          controller: _defaultCurator,
                          margin: EdgeInsets.zero)),
                ),

                // Allow enable vpn with no hops
                pady(8),
                Divider(),
                PageTile(
                  title:
                      s.allowNoHopVPN + "\n(" + s.trafficMonitoringOnly + ")",
                  trailing: Switch(
                    activeColor: AppColors.purple_3,
                    value: _allowNoHopVPN,
                    onChanged: (bool value) {
                      UserPreferences().allowNoHopVPN.set(value);
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

                // Advanced Configuration
                pady(8),
                Divider(),
                PageTile(
                  title: "Advanced Configuration",
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRoutes.configuration);
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
                /*
                pady(8),
                Divider(),
                PageTile(
                  title: s.showInstructions,
                  trailing: RaisedButton(
                    child: Text(s.reset),
                    onPressed: _resetInstructions,
                  ),
                ),
                 */

                // Logging
                if (_showLogging) ...[
                  pady(16),
                  PageTile.route(
                      title: "Logging",
                      routeName: '/settings/log',
                      context: context),
                ],

                // V1 UI opt-in
                pady(8),
                Divider(),
                PageTile(
                  title: "GUI Version 1",
                  trailing: Switch(
                    activeColor: AppColors.purple_3,
                    value: _guiV1,
                    onChanged: (bool value) async {
                      await UserPreferences().guiV1.set(value);
                      OrchidAPI().updateConfiguration();
                      AppDialogs.showConfigurationChangeSuccess(context, warnOnly: true);
                      setState(() {
                        _guiV1 = value;
                      });
                    },
                  ),
                ),


                // TESTING: Remove
                pady(8),
                Divider(),
                PageTile(
                  title: "(DEBUG) Reset Active Accounts",
                  trailing: RaisedButton(
                    child: Text("Reset"),
                    onPressed: () {
                      UserPreferences().activeAccounts.set([]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
