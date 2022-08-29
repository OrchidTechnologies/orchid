import 'package:orchid/orchid.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/orchid_switch.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/common/page_tile.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
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
  bool _tester = false;

  @override
  void initState() {
    super.initState();
    ScreenOrientation.all();
    initStateAsync();
    _defaultCurator.addListener(_curatorChanged);

    _queryBalances = UserPreferences().getQueryBalances();
    _defaultCurator.text =
        UserPreferences().getDefaultCurator() ?? OrchidHop.appDefaultCurator;
  }

  void initStateAsync() async {
    advancedConfigChanged();
    setState(() {});
  }

  /// Update system config based on changes to user advanced config
  void advancedConfigChanged() async {
    _tester = OrchidUserConfig.isTester;

    var jsConfig = OrchidUserConfig().getUserConfigJS();
    OrchidPlatform.pretendToBeAndroid =
        jsConfig.evalBoolDefault('isAndroid', false);

    setState(() {});
  }

  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var buttonStyle = OrchidText.button
        .copyWith(color: Colors.black, fontSize: 14, height: 1.5);

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
                      hintText: OrchidHop.appDefaultCurator,
                    )),
              )),

              // Balance query
              _divided(PageTile(
                height: height,
                title: s.queryBalances,
                trailing: OrchidSwitch(
                  value: _queryBalances,
                  onChanged: (bool value) {
                    UserPreferences().setQueryBalances(value);
                    setState(() {
                      _queryBalances = value;
                    });
                  },
                ),
              )),

              // RPC Settings
              _divided(PageTile.route(
                  // leading: Icon(Icons.cloud_outlined, color: Colors.white, size: 24),
                  leading: OrchidAsset.chain.unknown_chain_no_bg,
                  title: s.chainSettings,
                  routeName: '/settings/rpc',
                  context: context)),

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
              _divided(PageTile.route(
                  // height: height,
                  title: s.logging,
                  routeName: '/settings/log',
                  context: context)),

              if (_tester)
                _divided(PageTile(
                  title: "[TESTER] Reset First Launch Version",
                  trailing: RaisedButton(
                    color: OrchidColors.tappable,
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
                  title: "[TESTER] Clear cached accounts",
                  trailing: RaisedButton(
                    color: OrchidColors.tappable,
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

              if (_tester)
                _divided(PageTile(
                  title: "[TESTER] Remove all identities (keys)",
                  trailing: RaisedButton(
                    color: OrchidColors.tappable,
                    child: Text(
                      s.remove.toUpperCase(),
                      style: buttonStyle,
                    ),
                    onPressed: () async {
                      final activeKeyUids = await OrchidHop.getInUseKeyUids();
                      if (activeKeyUids.isNotEmpty) {
                        await AppDialogs.showAppDialog(
                            context: context,
                            title: s.orchidAccountInUse,
                            bodyText:
                                "One or more Orchid hops are using keys.  Unable to remove them.");
                        return;
                      }
                      AppDialogs.showConfirmationDialog(
                          context: context,
                          title: "Remove all identities?",
                          actionText: "REMOVE",
                          bodyText:
                              "Are you sure you want to remove all stored keys? Have you backed them up?",
                          commitAction: () async {
                            log("Clearing identities");
                            await UserPreferences()
                                .cachedDiscoveredAccounts
                                .clear();
                            await UserPreferences().keys.clear();
                          });
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
    setState(() {});
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
