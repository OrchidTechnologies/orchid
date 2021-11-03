import 'dart:math';

import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/orchid/orchid_text_field.dart';
import 'package:orchid/pages/account_manager/account_finder.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/page_tile.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/common/titled_page_base.dart';

import '../app_routes.dart';

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
    var buttonStyle = OrchidText.button
        .copyWith(color: Colors.black, fontSize: 14, height: 1.5);

    var activeThumbColor = Color(0xFFFC7EFF);
    var activeTrackColor = Color(0x61FC7EFF);
    var inactiveThumbColor = Color(0x99FFFFFF);
    var inactiveTrackColor = Color(0x61FFFFFF);

    final height = 56.0;
    return TitledPage(
      title: s.settings,
      decoration: BoxDecoration(),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Default curator
              _divided(PageTile(
                height: height,
                title: s.defaultCurator,
                trailing: Container(
                    width: min(275, screenWidth * 0.5),
                    child: OrchidTextField(
                      controller: _defaultCurator,
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                    )),
              )),

              // Balance query
              _divided(PageTile(
                height: height,
                title: s.queryBalances,
                trailing: Switch(
                  activeColor: activeThumbColor,
                  activeTrackColor: activeTrackColor,

                  // TODO: Why aren't these working?
                  inactiveThumbColor: inactiveThumbColor,
                  inactiveTrackColor: inactiveTrackColor,

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
              _divided(PageTile(
                height: height,
                title: s.advancedConfiguration,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 2.0),
                  child: Icon(Icons.settings, color: Colors.white, size: 20),
                ),
                onTap: () async {
                  await Navigator.pushNamed(context, AppRoutes.configuration);
                  advancedConfigChanged(); // update anything that may have changed via config
                },
              )),

              // Manage Data
              _divided(PageTile.route(
                  leading:
                      Icon(Icons.import_export, color: Colors.white, size: 24),
                  title: s.configurationManagement,
                  routeName: '/settings/manage_config',
                  context: context)),

              // Logging
              if (_showLogging || _tester)
                _divided(PageTile.route(
                    // height: height,
                    title: s.logging,
                    routeName: '/settings/log',
                    context: context)),

              if (_tester)
                _divided(PageTile(
                  title: "(TEST) Reset First Launch Version",
                  trailing: RaisedButton(
                    child: Text(
                      s.reset.toUpperCase(),
                      style: buttonStyle,
                    ),
                    onPressed: () {
                      UserPreferences()
                          .releaseVersion
                          .set(ReleaseVersion.resetFirstLaunch());
                    },
                  ),
                )),

              if (_tester)
                _divided(PageTile(
                  title: "(TEST) Clear cached accounts",
                  trailing: RaisedButton(
                    child: Text(
                      s.clear.toUpperCase(),
                      style: buttonStyle,
                    ),
                    onPressed: () async {
                      log("Clearing cached discovered accounts");
                      await UserPreferences().cachedDiscoveredAccounts.clear();
                      AppDialogs.showAppDialog(
                          context: context, title: "Cached accounts cleared.");
                    },
                  ),
                )),

              /*
              if (_tester)
                _divided(PageTile(
                  title: "(TEST) Test Active Account Migration",
                  trailing: RaisedButton(
                    child: Text(
                      s.reset.toUpperCase(),
                      style: buttonStyle,
                    ),
                    onPressed: () async {
                      log("Testing migration by setting an active account");
                      await UserPreferences().circuit.clear();
                      AccountFinder().find((accounts) async {
                        if (accounts.isNotEmpty) {
                          await UserPreferences()
                              .activeAccounts
                              .set([accounts.first]);
                          AppDialogs.showAppDialog(
                              context: context,
                              title: "Migration reset. Quit the app now.");
                        }
                      });
                    },
                  ),
                )),
               */

              /*
              if (_tester)
                _divided(PageTile(
                  title: "(TEST) Reset V1 Account Data",
                  trailing: RaisedButton(
                    child: Text(s.reset.toUpperCase(), style: buttonStyle),
                    onPressed: () {
                      UserPreferences().activeAccounts.set([]);
                      UserPreferences().cachedDiscoveredAccounts.set({});
                    },
                  ),
                )),
               */
            ],
          ),
        ),
      ),
    );
  }

  Widget _divided(Widget child) {
    return Column(
      children: [
        pady(8),
        Divider(color: Color(0xffE9E7E7)),
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
