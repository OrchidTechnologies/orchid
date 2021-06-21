import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/pages/circuit/config_change_dialogs.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/common/app_text_field.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/page_tile.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/common/titled_page_base.dart';

import '../../common/app_colors.dart';
import '../app_routes.dart';
import '../../common/app_sizes.dart';

/// The main settings page.
class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  var _defaultCurator = TextEditingController();

  // TODO: These switches should work directly with ObservablePreference
  bool _queryBalances = false;
  bool _showLogging = false;
  bool _guiV0 = false;
  bool _tester = false;

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
    _guiV0 = await UserPreferences().guiV0.get();

    advancedConfigChanged();
    setState(() {});
  }

  /// Update system config based on changes to user advanced config
  void advancedConfigChanged() async {
    var jsConfig = await OrchidUserConfig().getUserConfigJS();

    _showLogging = jsConfig.evalBoolDefault('logging', false);
    _tester = jsConfig.evalBoolDefault('tester', false);

    OrchidPlatform.pretendToBeAndroid =
        jsConfig.evalBoolDefault('isAndroid', false);

    setState(() {});
  }

  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    return TitledPage(
      title: s.settings,
      decoration: BoxDecoration(),
      child: Padding(
        padding: EdgeInsets.all(
            AppSize(context).tallerThan(AppSize.iphone_12_max) ? 128 : 0),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Accounts
                _item(PageTile(
                  title: s.deletedHops,
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRoutes.accounts);
                  },
                )),

                // Default curator
                _item(PageTile(
                  title: s.defaultCurator,
                  //imageName: "assets/images/assignment.png",
                  trailing: Container(
                      width: screenWidth * 0.5,
                      child: AppTextField(
                          controller: _defaultCurator,
                          margin: EdgeInsets.zero)),
                )),

                // Balance query
                _item(PageTile(
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
                )),

                // Advanced Configuration
                _item(PageTile(
                  title: s.advancedConfiguration,
                  onTap: () async {
                    await Navigator.pushNamed(context, AppRoutes.configuration);
                    advancedConfigChanged(); // update anything that may have changed via config
                  },
                )),

                // Manage Data
                _item(PageTile.route(
                    title: s.configurationManagement,
                    routeName: '/settings/manage_config',
                    context: context)),

                // Logging
                if (_showLogging || _tester)
                  _item(PageTile.route(
                      title: s.logging,
                      routeName: '/settings/log',
                      context: context)),

                // V1 UI opt-out
                _item(Column(
                  children: [
                    PageTile(
                      title: s.enableMultihopUi,
                      trailing: Switch(
                        activeColor: AppColors.purple_3,
                        value: _guiV0,
                        onChanged: (bool value) async {
                          await UserPreferences().guiV0.set(value);
                          OrchidAPI().updateConfiguration();
                          ConfigChangeDialogs.showConfigurationChangeSuccess(context,
                              warnOnly: true);
                          setState(() {
                            _guiV0 = value;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 24, top: 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning, color: Colors.deepPurple),
                          padx(12),
                          Expanded(
                            child: Text(
                                s.ifYouWantToUseMultihopOpenvpnAndWireguardYoull,
                                style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),

                if (_tester)
                  _item(PageTile(
                    title: "(TEST) Reset First Launch",
                    trailing: RaisedButton(
                      child: Text(s.reset),
                      onPressed: () {
                        UserPreferences()
                            .releaseVersion
                            .set(ReleaseVersion.firstLaunch());
                      },
                    ),
                  )),

                if (_tester)
                  _item(PageTile(
                    title: "(TEST) Reset V1 Account Data",
                    trailing: RaisedButton(
                      child: Text(s.reset),
                      onPressed: () {
                        UserPreferences().activeAccounts.set([]);
                        UserPreferences().cachedDiscoveredAccounts.set({});
                      },
                    ),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(Widget child) {
    return Column(
      children: [
        pady(8),
        Divider(),
        child,
      ],
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
