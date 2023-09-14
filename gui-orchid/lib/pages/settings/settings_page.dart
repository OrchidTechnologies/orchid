import 'package:orchid/api/preferences/user_preferences_keys.dart';
import 'package:orchid/vpn/preferences/release_version.dart';
import 'package:orchid/orchid/orchid.dart';
import 'dart:math';
import 'package:orchid/api/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/common/app_buttons_deprecated.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/orchid/orchid_switch.dart';
import 'package:orchid/orchid/field/orchid_text_field.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';
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

    _queryBalances = UserPreferencesVPN().getQueryBalances();
    _defaultCurator.text =
        UserPreferencesVPN().getDefaultCurator() ?? OrchidHop.appDefaultCurator;
  }

  void initStateAsync() async {
    advancedConfigChanged();
    setState(() {});
  }

  /// Update system config based on changes to user advanced config
  void advancedConfigChanged() async {
    _tester = OrchidUserConfig.isTester;

    var jsConfig = OrchidUserConfig().getUserConfig();
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
      title: context.s.settings,
      // decoration: BoxDecoration(),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Default curator
              _divided(PageTile(
                height: height,
                title: context.s.defaultCurator,
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
                title: context.s.queryBalances,
                trailing: OrchidSwitch(
                  value: _queryBalances,
                  onChanged: (bool value) {
                    UserPreferencesVPN().setQueryBalances(value);
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
                  title: context.s.chainSettings,
                  routeName: '/settings/rpc',
                  context: context)),

              // Advanced Configuration
              _divided(PageTile(
                height: height,
                title: context.s.advancedConfiguration,
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
                  title: context.s.configurationManagement,
                  routeName: '/settings/manage_config',
                  context: context)),

              // Logging
              _divided(PageTile.route(
                  // height: height,
                  title: context.s.logging,
                  routeName: '/settings/log',
                  context: context)),

              if (_tester)
                _divided(PageTile(
                  title: "[TESTER] Reset First Launch Version",
                  trailing: RaisedButtonDeprecated(
                    color: OrchidColors.tappable,
                    child: Text(
                      context.s.reset.toUpperCase(),
                      style: buttonStyle,
                    ),
                    onPressed: _resetFirstLaunch,
                  ),
                )),

              if (_tester)
                _divided(PageTile(
                  title: "[TESTER] Clear cached accounts",
                  trailing: RaisedButtonDeprecated(
                    color: OrchidColors.tappable,
                    child: Text(
                      context.s.clear.toUpperCase(),
                      style: buttonStyle,
                    ),
                    onPressed: _clearCachedAccounts,
                  ),
                )),

              if (_tester)
                _divided(PageTile(
                  title: "[TESTER] Remove all identities (keys)",
                  trailing: RaisedButtonDeprecated(
                    color: OrchidColors.tappable,
                    child: Text(
                      context.s.remove.toUpperCase(),
                      style: buttonStyle,
                    ),
                    onPressed: _confirmClearAllKeysAndAccounts,
                  ),
                )),

              if (_tester)
                _divided(PageTile(
                  title: "[TESTER] Reset everything",
                  trailing: RaisedButtonDeprecated(
                    color: OrchidColors.tappable,
                    child: Text(
                      "RESET ALL",
                      style: buttonStyle,
                    ),
                    onPressed: () async {
                      AppDialogs.showConfirmationDialog(
                        context: context,
                        title: "Reset EVERYTHING?",
                        actionText: "RESET",
                        bodyText:
                            "Are you sure you want to reset all state including your keys?  Have you backed them up?",
                        commitAction: _resetEverything,
                      );
                    },
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }

  void _resetEverything() async {
    log("Clearing everything");
    await UserPreferencesVPN().circuit.clear();
    await _clearAllKeysAndAccounts();
    await _resetFirstLaunch();
    Navigator.pop(context);
    Navigator.pop(context);
  }

  void _confirmClearAllKeysAndAccounts() async {
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
          await _clearAllKeysAndAccounts();
        });
  }

  Future<void> _clearAllKeysAndAccounts() async {
    await UserPreferencesVPN().cachedDiscoveredAccounts.clear();
    await UserPreferencesKeys().keys.clear();
  }

  void _clearCachedAccounts() async {
    log("Clearing cached discovered accounts");
    await UserPreferencesVPN().cachedDiscoveredAccounts.clear();
    await AppDialogs.showAppDialog(
        context: context, title: "Cached accounts cleared.");
  }

  Future<void> _resetFirstLaunch() async {
    await UserPreferencesVPN()
        .releaseVersion
        .set(ReleaseVersion.resetFirstLaunch());
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
    UserPreferencesVPN().setDefaultCurator(_defaultCurator.text);
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    _defaultCurator.removeListener(_curatorChanged);
  }
}
