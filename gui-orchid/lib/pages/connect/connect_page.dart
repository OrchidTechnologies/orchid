import 'dart:async';
import 'package:orchid/vpn/preferences/release_version.dart';
import 'package:orchid/orchid/orchid.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_bandwidth_pricing.dart';
import 'package:orchid/api/preferences/user_preferences_keys.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/vpn/monitoring/restart_manager.dart';
import 'package:orchid/api/orchid_eth/orchid_lottery.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/api/orchid_eth/orchid_account_detail.dart';
import 'package:orchid/pages/account_manager/account_manager_page.dart';
import 'package:orchid/pages/circuit/circuit_utils.dart';
import 'package:orchid/vpn/model/circuit.dart';
import 'package:orchid/vpn/model/circuit_hop.dart';
import 'package:orchid/pages/connect/manage_accounts_card.dart';
import 'package:orchid/orchid/orchid_action_button.dart';
import 'package:orchid/orchid/orchid_logo.dart';
import 'package:orchid/vpn/model/orchid_hop.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/pages/connect/release.dart';
import 'package:orchid/pages/connect/welcome_panel.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'connect_page_utils.dart';
import 'connect_status_panel.dart';

/// The main page containing the connect button.
class ConnectPage extends StatefulWidget {
  ConnectPage({Key? key}) : super(key: key);

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
  late bool _routingEnabled;
  late bool _monitoringEnabled;
  bool _restarting = false;

  late Timer _updateStatsTimer;

  // Circuit configuration
  Circuit? _circuit;

  // Key that increments on changes to the circuit
  int _circuitKey = 0;

  // Circuit hop count or zero when no circuit or not loaded
  int get _circuitHops {
    return _circuit?.hops.length ?? 0;
  }

  // There is a valid circuit and it has one or more hops
  bool get _circuitHasHops {
    return _circuitHops > 0;
  }

  // The hop selected on the manage accounts card
  int _selectedIndex = 0;

  // The selected hop on the account card or null
  CircuitHop? get _selectedHop {
    if (!_circuitHasHops) {
      return null;
    }
    return _circuit!.hops[_selectedIndex];
  }

  // The account associated with the selected hop on the account card or null.
  Account? get _selectedAccount {
    if (_selectedHop != null && _selectedHop is OrchidHop) {
      return (_selectedHop as OrchidHop).account;
    } else {
      return null;
    }
  }

  AccountDetailPoller? _selectedAccountPoller;

  // V1 status data
  USD? _bandwidthPrice;
  double? _bandwidthAvailableGB; // GB

  late NeonOrchidLogoController _logoController;

  // True if there are cached accounts for any identity. Initially null.
  bool? _hasAccounts;

  // True if the user has one or more identities (keys).  Initially null.
  // bool _hasIdentity;

  // The user's keys (null until initialized).
  List<StoredEthereumKey>? _keys;

  // The most recently generated or imported key or null if there are none.
  StoredEthereumKey? get _latestKey {
    return (_keys ?? []).isEmpty
        ? null
        : _keys!.reduce((a, b) => a.time.isAfter(b.time) ? a : b);
  }

  // May be empty but not null once loaded.
  bool get _initialized => _hasAccounts != null && _keys != null;

  // Show the welcome pane if the user has not created any accounts.
  bool get _showWelcomePane => _initialized && !(_hasAccounts ?? false);

  // User toggle for display of the panel
  bool _showWelcomePaneMinimized = false;

  @override
  void initState() {
    super.initState();
    ScreenOrientation.reset();

    _initListeners();

    _updateStatsTimer = Timer.periodic(Duration(seconds: 30), _updateStats);
    _updateStats(null);

    _launchCheckItems();
    // _scanForAccountsIfNeeded();

    _logoController = NeonOrchidLogoController(vsync: this);

    // Note: There seems to be a bug in SharedPreferences where accessing it
    // Note: too early during startup causes problems for this setup.
    Future.delayed(Duration(seconds: 0)).then((_) {
      ConnectPageUtils.checkStartupCommandArgs(context);
    });
  }

  /// Update alerts, badging, and status information.
  Future<void> _updateStats(timer) async {
    try {
      await _selectedAccountPoller?.pollOnce();
    } catch (err) {
      log("eror refreshing account details: $err");
    }

    // update bandwidth price
    try {
      _bandwidthPrice = await OrchidBandwidthPricing.getBandwidthPrice();
    } catch (err) {
      log("error getting bandwidth price: $err");
    }

    // update bandwidth available estimate
    if (_selectedAccount != null) {
      try {
        LotteryPot pot = await _selectedAccount!.getLotteryPot();
        var tokenToUsd = await OrchidPricing().tokenToUsdRate(pot.balance.type);
        _bandwidthAvailableGB =
            pot.balance.floatValue * tokenToUsd / _bandwidthPrice!.value;
      } catch (err) {
        _bandwidthAvailableGB = null;
        log("error calculating bandwidth available: $err");
      }
    } else {
      _bandwidthAvailableGB = null;
    }
  }

  // Note: We should migrate to a provider context
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

    // Monitor routing preference
    UserPreferencesVPN().routingEnabled.stream().listen((enabled) {
      log("connect: routing enabled changed: $enabled");
      setState(() {
        _routingEnabled = enabled;
      });
    }).dispose(_subs);

    // Monitor traffic monitoring preference
    UserPreferencesVPN().monitoringEnabled.stream().listen((enabled) {
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

    // Monitor identities
    UserPreferencesKeys().keys.stream().listen((keys) async {
      setState(() {
        _keys = keys;
      });
    }).dispose(_subs);

    // Monitor found accounts
    UserPreferencesVPN()
        .cachedDiscoveredAccounts
        .stream()
        .listen((accounts) async {
      log("XXX: cachedDiscoveredAccounts = $accounts");
      setState(() {
        _hasAccounts = accounts.isNotEmpty;
      });
    }).dispose(_subs);
  }

  @override
  Widget build(BuildContext context) {
    try {
      log("XXX: first launch: "
          "_initialized == $_initialized, "
          "_hasAccounts == $_hasAccounts, "
          "_keys = $_keys,"
          "_latestKey == $_latestKey, "
          "_showWelcomePane = $_showWelcomePane");
    } catch (err) {
      log("first launch: Error should not happen: $err");
    }

    return Stack(
      children: <Widget>[
        if (!isReallyShort)
          Align(
            alignment: Alignment.topCenter,
            child: AnimatedBuilder(
                animation: _logoController.listenable,
                builder: (BuildContext context, Widget? child) {
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
            child: _buildPageContent(),
          ),
        ),

        // The connect button
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: _showWelcomePane ? 40 : 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 300, child: _buildStatusMessageLine()),
                pady(20),
                _buildConnectButton(),
              ],
            ),
          ),
        ),

        // The welcome panel
        if (_showWelcomePane && !_showWelcomePaneMinimized)
          Align(
            alignment: Alignment.center,
            child: WelcomePanel(
              defaultIdentity: _latestKey,
              onDismiss: () {
                setState(() {
                  _showWelcomePaneMinimized = true;
                });
              },
              onAccount: (account) async {
                log("XXX: account import: $account");
                if (await CircuitUtils.defaultCircuitIfNeededFrom(account)) {
                  CircuitUtils.showDefaultCircuitCreatedDialog(context);
                }
                // AccountFinder.shared?.refresh();
              },
            ).pady(40).top(24),
          )
      ],
    );
  }

  Widget _buildConnectButton() {
    String text;
    if (_restarting) {
      text = s.restarting;
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
    bool buttonEnabled = ( // Enabled when there is a circuit
            _circuitHasHops ||
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
        if (_showWelcomePane && _showWelcomePaneMinimized)
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: _buildWelcomePaneMinimized(),
          ),
        Spacer(flex: 2),
      ],
    );
  }

  Widget _buildWelcomePaneMinimized() {
    return SizedBox(
      width: 308,
      height: 56,
      child: OrchidPanel(
        highlight: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: TextButton(
            onPressed: () {
              setState(() {
                _showWelcomePaneMinimized = false;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_time_rounded, color: Colors.white),
                padx(8),
                Text(s.quickFundAnAccount, style: OrchidText.body1).height(1.8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManageAccountsCard() {
    return ManageAccountsCard(
      key: Key(_circuitKey.toString()),
      circuit: _circuit,
      minHeight: isShort,
      onSelectIndex: (index) {
        setState(() {
          _selectedIndex = index;
          _selectedAccountChanged(_selectedAccount);
        });
      },
      onManageAccountsPressed: () async {
        await AccountManagerPage.showAccount(context, _selectedAccount);
        _updateStats(null);
      },
    );
  }

  // only shows for v1
  Widget _buildStatusPanel() {
    return ConnectStatusPanel(
      key: Key(_selectedAccount?.signerKeyUid ?? ""),
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
            message = _circuitHasHops ? s.pushToConnect : '';
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
        message = s.pausingAllTraffic + '\n' + s.queryingEthereumForARandom;
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

    return Text(
      message,
      style: OrchidText.caption,
      textAlign: TextAlign.center,
    );
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
      case OrchidVPNRoutingState.VPNDisconnecting:
        _logoController.pulseHalf();
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
    UserPreferencesVPN().routingEnabled.set(!_routingEnabled);
  }

  /// Do first launch and per-release activities.
  Future<void> _launchCheckItems() async {
    // Show release notes if needed
    log("first launch: check.");
    var lastVersion = await _getReleaseVersionWithOverride();
    if (lastVersion.isFirstLaunch) {
      log("first launch: is first launch");
    } else {
      // show any release notes since the last viewed
      log("connect: check release notes since version: $lastVersion");
      if (lastVersion.isOlderThan(Release.current)) {
        await _showReleaseNotesSince(lastVersion);
      }
    }

    await UserPreferencesVPN().releaseVersion.set(Release.current);
  }

  // Allow override of the last viewed release notes version for testing.
  // e.g. set to 0 to see all release notes, or high to hide them.
  Future<ReleaseVersion> _getReleaseVersionWithOverride() async {
    var version = UserPreferencesVPN().releaseVersion.get()!;

    const release_version = 'release_version';
    // From user config
    var jsConfig = OrchidUserConfig().getUserConfig();
    int? overrideVersion = jsConfig.evalIntDefaultNull(release_version);
    if (overrideVersion != null) {
      version = ReleaseVersion(overrideVersion);
    }

    // From command line
    overrideVersion =
        const int.fromEnvironment(release_version, defaultValue: -1);
    if (overrideVersion != -1) {
      version = ReleaseVersion(overrideVersion);
    }

    return version;
  }

  Future<void> _showReleaseNotesSince(ReleaseVersion lastVersion) async {
    return AppDialogs.showAppDialog(
      context: context,
      title: await Release.whatsNewTitle(context),
      body: await Release.messagesSince(context, lastVersion),
    );
  }

  Future _circuitConfigurationChanged() async {
    var prefs = UserPreferencesVPN();
    _circuit = prefs.circuit.get();
    _selectedIndex = 0;

    // Update the card... need a key
    _circuitKey += 1;

    _selectedAccountChanged(_selectedAccount);
    setState(() {});
  }

  // TODO: remove this selected account logic and simplify update stats
  // The selected account has changed, update or remove the account detail poller.
  // Manage the selected account (the account that is forefront on the manage accoutns
  // card).
  Future _selectedAccountChanged(Account? account) async {
    _selectedAccountPoller?.cancel();
    if (account != null) {
      _selectedAccountPoller = AccountDetailPoller(account: account);
      try {
        await _selectedAccountPoller!.pollOnce(); // poll once
      } catch (err) {
        log("Error: $err");
      }
    } else {
      _selectedAccountPoller = null;
    }
    await _updateStats(null);
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
    // AccountFinder.shared?.dispose();
    _updateStatsTimer.cancel();
    _subs.dispose();
  }
}
