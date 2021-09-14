import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/api/monitoring/restart_manager.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/pages/account_manager/account_detail_poller.dart';
import 'package:orchid/pages/account_manager/account_store.dart';
import 'package:orchid/pages/connect/manage_accounts_card.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/pages/connect/release.dart';
import 'package:orchid/pages/connect/welcome_panel.dart';
import 'package:orchid/util/on_off.dart';
import 'package:orchid/util/streams.dart';
import 'package:orchid/util/units.dart';

import '../app_routes.dart';
import 'connect_status_panel.dart';

/// The main page containing the connect button.
class ConnectPage extends StatefulWidget {
  ConnectPage({Key key}) : super(key: key);

  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage>
    with TickerProviderStateMixin {
  List<StreamSubscription> _subs = [];

  // Current routing state reflected by the page, driving color and animation.
  OrchidVPNRoutingState _routingState = OrchidVPNRoutingState.VPNNotConnected;

  // Lower level vpn state, used in the detail status message.
  OrchidVPNExtensionState _vpnState = OrchidVPNExtensionState.Invalid;

  // Routing and monitoring status
  bool _routingEnabled;
  bool _monitoringEnabled;
  bool _restarting = false;

  Timer _updateStatsTimer;
  bool _guiV1 = true;

  // Circuit configuration
  int _circuitHops; // @nullable

  // V0 status data
  bool get _hasConfiguredCircuit {
    return _circuitHops != null;
  }

  // V1 status data
  AccountDetailPoller _activeAccount;
  USD _bandwidthPrice;
  double _bandwidthAvailableGB; // GB

  bool get _showWelcomePane => _activeAccount == null && _guiV1;

  NeonOrchidLogoController _logoController;

  @override
  void initState() {
    super.initState();
    ScreenOrientation.reset();

    _initListeners();

    _updateStatsTimer = Timer.periodic(Duration(seconds: 30), _updateStats);
    _updateStats(null);

    _releaseVersionCheck();

    _logoController = NeonOrchidLogoController(vsync: this);
  }

  /// Update alerts, badging, and status information.
  void _updateStats(timer) async {
    if (await UserPreferences().guiV0.get()) {
      await _updateStatsV0();
    } else {
      await _updateStatsV1();
    }
  }

  // Update stats and alerts
  Future<void> _updateStatsV1() async {
    try {
      await _activeAccount?.refresh();
    } catch (err) {
      log("eror refreshing account details: $err");
    }
    try {
      _bandwidthPrice = await OrchidEthereumV1.getBandwidthPrice();
    } catch (err) {
      log("error getting bandwidth price: $err");
    }
    if (_activeAccount != null) {
      try {
        var tokenToUsd = await OrchidPricing()
            .tokenToUsdRate(_activeAccount.lotteryPot.balance.type);
        _bandwidthAvailableGB = _activeAccount.lotteryPot.balance.floatValue *
            tokenToUsd /
            _bandwidthPrice.value;
      } catch (err) {
        _bandwidthAvailableGB = null;
        log("error calculating bandwidth available: $err");
      }
    }
  }

  // Note: Should be consolidated with logic in circuit page.
  /// Check market conditions for V0 hops
  Future<void> _updateStatsV0() async {
    var hops = (await UserPreferences().getCircuit()).hops;
    var keys = await UserPreferences().getKeys();
    for (var hop in hops) {
      if (hop is OrchidHop) {
        try {
          var pot = await OrchidEthereumV0.getLotteryPot(
              hop.funder, hop.getSigner(keys));

          var efficiency = (await MarketConditionsV0.forPot(pot)).efficiency;
          return efficiency < MarketConditions.minEfficiency;
        } catch (err) {
          log("Error fetching lottery pot 2: err");
        }
      }
    }
  }

  // TODO: We should migrate to a provider context
  /// Listen for changes in Orchid network status.
  void _initListeners() async {
    log('Connect Page: Init listeners...');

    // Monitor connection status
    OrchidAPI().vpnRoutingStatus.listen((OrchidVPNRoutingState state) {
      log('[connect page] Connection status changed: $state');
      _routingStateChanged(state);
    }).dispose(_subs);

    // Monitor circuit changes
    OrchidAPI().circuitConfigurationChanged.listen((value) {
      _circuitConfigurationChanged();
      _updateStats(null); // refresh alert status
    }).dispose(_subs);

    // Monitor changes in the UI version preference
    UserPreferences().guiV0.stream().listen((guiV0) async {
      _guiV1 = !guiV0;
      if (_guiV1) {
        await _activeAccountChanged(await Account.activeAccount);
      }
      await _circuitConfigurationChanged();
      _updateStats(null);
    }).dispose(_subs);

    // Monitor routing preference
    UserPreferences().routingEnabled.stream().listen((enabled) {
      log("routing enabled changed: $enabled");
      setState(() {
        _routingEnabled = enabled;
      });
    }).dispose(_subs);

    // Monitor traffic monitoring preference
    UserPreferences().monitoringEnabled.stream().listen((enabled) {
      setState(() {
        _monitoringEnabled = enabled;
      });
    }).dispose(_subs);

    // Monitor automated restarts
    OrchidRestartManager().restarting.stream.listen((value) {
      setState(() {
        _restarting = value;
      });
    }).dispose(_subs);

    // Monitor low level vpn changes for the status line.
    OrchidAPI().vpnExtensionStatus.stream.listen((value) {
      setState(() {
        _vpnState = value;
      });
    }).dispose(_subs);

    // Monitor v1 account selection
    Account.activeAccountStream.listen((account) async {
      try {
        await _activeAccountChanged(account);
      } catch (err) {
        log("error in v1 account selection: $err");
      }
    }).dispose(_subs);
    // Prime with the current account
    _activeAccountChanged(await Account.activeAccount);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        if (!isReallyShort)
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
                animation: _logoController.listenable,
                builder: (BuildContext context, Widget child) {
                  return NeonOrchidLogo(
                    light: _logoController.value,
                    offset: _logoController.offset,
                  );
                  // return NeonOrchidLogo(light: 1.0);
                }),
          ),

        // The page content including the button title, button, and route info when connected.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            // padding: EdgeInsets.zero,
            child: _buildPageContent(),
          ),
        ),

        // The connect button
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: _showWelcomePane ? 80 : 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusMessageLine(),
                pady(20),
                _buildConnectButton(),
              ],
            ),
          ),
        ),

        // The welcome panel
        if (_showWelcomePane)
          Container(
            alignment: Alignment.bottomCenter,
            child: WelcomePanel(),
          )
      ],
    );
  }

  Widget _buildConnectButton() {
    String text;
    if (_restarting) {
      text = "Restarting";
    } else {
      switch (_routingState) {
        case OrchidVPNRoutingState.VPNDisconnecting:
          text = s.disconnecting;
          break;
        case OrchidVPNRoutingState.VPNConnecting:
          text = s.starting; // vpn is starting
          break;
        case OrchidVPNRoutingState.VPNConnected:
          text = s.connecting; // orchid is connecting
          break;
        case OrchidVPNRoutingState.VPNNotConnected:
          text = s.connect;
          break;
        case OrchidVPNRoutingState.OrchidConnected:
          text = s.disconnect;
      }
    }
    bool buttonEnabled =
        ( // Enabled when there is a circuit (or overridden for traffic monitoring)
                _hasConfiguredCircuit ||
                    // TODO:
                    // Enabled if we are already connected (corner case of changed config while connected).
                    _routingState == OrchidVPNRoutingState.VPNConnecting ||
                    _routingState == OrchidVPNRoutingState.VPNConnected ||
                    _routingState == OrchidVPNRoutingState.OrchidConnected) &&
            !_restarting;

    return OrchidActionButton(
      enabled: buttonEnabled,
      text: text.toUpperCase(),
      onPressed: _onConnectButtonPressed,
    );
  }

  /// The page content including the button title, button, and route info when connected.
  Widget _buildPageContent() {
    return Column(
      children: <Widget>[
        if (!isReallyShort) Spacer(flex: isShort ? 2 : 3),
        _buildManageAccountsCard(),
        pady(24),
        _buildStatusPanel(),
        Spacer(flex: 2),
        if (_activeAccount == null) Spacer(flex: 1)
      ],
    );
  }

  GestureDetector _buildManageAccountsCard() {
    return GestureDetector(
        onTap: () async {
          await AppRoutes.pushAccountManager(context);
          _updateStats(null);
        },
        child: ManageAccountsCard(
          accountDetail: _activeAccount,
          minHeight: isShort,
        ));
  }

  // only shows for v1
  Widget _buildStatusPanel() {
    return ConnectStatusPanel(
      key: Key(_activeAccount?.account?.identityUid ?? ""),
      minHeight: isShort,
      bandwidthPrice: _bandwidthPrice,
      circuitHops: _circuitHops,
      bandwidthAvailableGB: _bandwidthAvailableGB,
    );
  }

  Widget _buildStatusMessageLine() {
    String message;

    // The status message generally follows the routing state
    switch (_routingState) {
      case OrchidVPNRoutingState.VPNDisconnecting:
        message = s.orchidDisconnecting;
        break;
      case OrchidVPNRoutingState.VPNConnecting:
        message = s.orchidConnecting;
        break;
      case OrchidVPNRoutingState.VPNNotConnected:
        // Routing not connected, show vpn state if needed
        switch (_vpnState) {
          case OrchidVPNExtensionState.Invalid:
          case OrchidVPNExtensionState.NotConnected:
            message = s.pushToConnect;
            break;
          case OrchidVPNExtensionState.Connecting:
            message = s.startingVpn;
            break;
          case OrchidVPNExtensionState.Disconnecting:
            message = s.disconnectingVpn;
            break;
          case OrchidVPNExtensionState.Connected:
            if (!_routingEnabled) {
              message = s.orchidAnalyzingTraffic;
            } else {
              message = s.vpnConnectedButNotRouting;
            }
            break;
        }
        break;
      case OrchidVPNRoutingState.VPNConnected:
        message = s.connectingToARandomOrchidProvider;
        break;
      case OrchidVPNRoutingState.OrchidConnected:
        if (_monitoringEnabled) {
          message = s.orchidRunningAndAnalyzing;
        } else {
          message = s.orchidIsRunning;
        }
    }

    if (_restarting) {
      message = s.restarting + ': ' + message;
    }

    return Text(message, style: OrchidText.caption);
  }

  /// Called upon a change to Orchid connection state
  void _routingStateChanged(OrchidVPNRoutingState state) async {
    _routingState = state;

    switch (state) {
      case OrchidVPNRoutingState.VPNNotConnected:
        _logoController.off();
        break;
      case OrchidVPNRoutingState.VPNConnecting:
      case OrchidVPNRoutingState.VPNConnected:
        _logoController.pulseHalf();
        break;
      case OrchidVPNRoutingState.VPNDisconnecting:
        _logoController.half();
        break;
      case OrchidVPNRoutingState.OrchidConnected:
        _logoController.full();
        break;
    }

    if (mounted) {
      setState(() {});
    }
  }

  /// Toggle the current connection state
  void _onConnectButtonPressed() async {
    UserPreferences().routingEnabled.set(!_routingEnabled);
  }

  /// Do first launch and per-release activities.
  Future<void> _releaseVersionCheck() async {
    var version = await UserPreferences().releaseVersion.get();

    log("first launch check.");
    if (version.isFirstLaunch) {
      await _doFirstLaunchActivities();
    }

    log("new version check.");
    if (version.isOlderThan(Release.current)) {
      await _doNewReleaseActivities();
    }

    await UserPreferences().releaseVersion.set(Release.current);
  }

  Future<void> _doFirstLaunchActivities() async {
    log("first launch: Do first launch activities.");
    // If this is a new user with no identities create one.
    var identities = await UserPreferences().getKeys();
    if (identities.isEmpty) {
      log("first launch: Creating default identity");
      var key = StoredEthereumKey.generate();
      await UserPreferences().addKey(key);

      // Select it
      AccountStore().setActiveIdentity(key);
    }

    // If this is an existing user with a 1-hop config migrate it to
    // the active account in V1.
    var circuit = await UserPreferences().getCircuit();
    if (circuit.hops.length == 1 && circuit.hops[0] is OrchidHop) {
      log("first launch: User has a 1-hop Orchid config, migrating.");
      var hop = circuit.hops[0] as OrchidHop;
      var account = Account(
          identityUid: hop.keyRef.keyUid,
          version: 0,
          chainId: Chains.Ethereum.chainId,
          funder: hop.funder);
      // Store the active account and publish the new config
      AccountStore().setActiveAccount(account);
    }
  }

  Future<void> _doNewReleaseActivities() async {
    log("new release: Do new release activities.");
    return AppDialogs.showAppDialog(
      context: context,
      title: await Release.title(context),
      body: Release.message(context),
    );
  }

  Future _circuitConfigurationChanged() async {
    var prefs = UserPreferences();
    if (await prefs.guiV0.get()) {
      _circuitHops = (await prefs.getCircuit()).hops.length;
    } else {
      var accountStore = await AccountStore(discoverAccounts: false).load();
      // Currently assumes single hop for V1
      _circuitHops = accountStore.activeAccount != null ? 1 : null;
    }
    setState(() {});
  }

  // The v1 active account has changed, update or remove the account detail poller.
  Future _activeAccountChanged(Account account) async {
    if (UserPreferences().guiV0.value) {
      return;
    }
    if (account != null) {
      _activeAccount = AccountDetailPoller(account: account);
      try {
        await _activeAccount.refresh(); // poll once
      } catch (err) {
        log("Error: $err");
      }
    } else {
      _activeAccount = null;
    }
    setState(() {});
  }

  bool get isShort {
    return AppSize(context).shorterThan(Size(0, 700));
  }

  bool get isReallyShort {
    return AppSize(context).shorterThan(Size(0, 590));
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    _updateStatsTimer.cancel();
    _subs.dispose();
  }

  S get s {
    return S.of(context);
  }
}
