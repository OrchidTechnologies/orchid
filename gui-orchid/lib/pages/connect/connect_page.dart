import 'dart:async';
import 'dart:ui';
import 'package:badges/badges.dart';
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
import 'package:orchid/pages/account_manager/account_detail_poller.dart';
import 'package:orchid/pages/account_manager/account_store.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/gradients.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/common/app_colors.dart';
import 'package:orchid/pages/connect/release.dart';
import 'package:orchid/pages/connect/welcome_panel.dart';
import 'package:orchid/util/streams.dart';
import 'package:orchid/util/units.dart';

import '../app_routes.dart';
import 'connect_status_panel.dart';

/// The main page containing the connect button.
class ConnectPage extends StatefulWidget {
  final ValueNotifier<Color> appBarColor;
  final ValueNotifier<Color> iconColor;

  ConnectPage({Key key, @required this.appBarColor, @required this.iconColor})
      : super(key: key);

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

  // Animation controller for transitioning to the connected state
  AnimationController _connectAnimController;

  // Animations driven by the connected state
  Animation<LinearGradient> _backgroundGradient;
  Animation<Color> _iconColor;

  // Routing and monitoring status
  bool _routingEnabled;
  bool _monitoringEnabled;
  bool _restarting;

  Timer _checkAlertsTimer;
  bool _showManageAccountsBadge = false;
  bool _guiV1 = true;

  // V0 status data
  bool _hasConfiguredCircuit = false;

  // V1 status data
  AccountDetailPoller _activeAccount;
  USD _bandwidthPrice;

  bool get _showWelcomePane => _activeAccount == null && _guiV1;

  @override
  void initState() {
    super.initState();
    _initListeners();
    _initAnimations();

    _checkAlertsTimer = Timer.periodic(Duration(seconds: 30), _checkAlerts);
    _checkAlerts(null);

    _releaseVersionCheck();
  }

  /// Update alerts, badging, and status information.
  void _checkAlerts(timer) async {
    bool showBadge = (await UserPreferences().guiV0.get())
        ? await _checkHopAlertsV0()
        : await _checkAlertsV1();
    if (mounted) {
      setState(() {
        _showManageAccountsBadge = showBadge;
      });
    }
  }

  Future<bool> _checkAlertsV1() async {
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
    return _activeAccount?.showMarketStatsAlert ?? false;
  }

  // Note: Should be consolidated with logic in circuit page.
  /// Check market conditions for V0 hops
  Future<bool> _checkHopAlertsV0() async {
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
    return false;
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
      _checkAlerts(null); // refresh alert status
    }).dispose(_subs);

    // Monitor changes in the UI version preference
    UserPreferences().guiV0.stream().listen((guiV0) async {
      _guiV1 = !guiV0;
      if (_guiV1) {
        await _activeAccountChanged(await Account.activeAccount);
      }
      await _circuitConfigurationChanged();
      _checkAlerts(null);
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
        // background gradient
        _buildBackgroundGradient(),

        // The page content including the button title, button, and route info when connected.
        SafeArea(
          child: _buildPageContent(),
        ),

        // The welcome panel
        if (_showWelcomePane)
          SafeArea(
            child: Container(
              alignment: Alignment.bottomCenter,
              child: WelcomePanel(),
            ),
          )
      ],
    );
  }

  /// The page content including the button title, button, and route info when connected.
  Widget _buildPageContent() {
    return OrientationBuilder(
        builder: (BuildContext context, Orientation builderOrientation) {
      var tall = AppSize(context).tallerThan(AppSize.iphone_se);
      return Column(
        children: <Widget>[
          // Line art background, logo, and connect button
          Expanded(
            flex: 12,
            child: _buildCenterControls(),
          ),

          if (_guiV1 && tall) Spacer(flex: 1),
          if (_guiV1 && tall) _buildStatusPanel(),

          if (tall) Spacer(flex: 1),
          if (tall) _buildManageAccountsButton(),

          Spacer(flex: 2),
        ],
      );
    });
  }

  // only shows for v1
  Widget _buildStatusPanel() {
    if (_activeAccount?.account == null) {
      return Container();
    }
    return ConnectStatusPanel(
      key: Key(_activeAccount?.account?.identityUid ?? ""),
      darkBackground: _showConnectedBackground(),
      data: _activeAccount,
      bandwidthPrice: _bandwidthPrice,
    );
  }

  Padding _buildManageAccountsButton() {
    var textColor =
        _showConnectedBackground() ? Colors.white : AppColors.purple_3;
    var bgColor = Colors.transparent;
    var borderColor = AppColors.purple_3;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 300),
        child: Container(
          height: 50,
          width: double.infinity,
          child: FlatButton(
              color: bgColor,
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: borderColor, width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(24))),
              onPressed: () async {
                if (await UserPreferences().guiV0.get()) {
                  await Navigator.pushNamed(context, AppRoutes.circuit);
                } else {
                  await Navigator.pushNamed(context, AppRoutes.identity);
                }
                _checkAlerts(null);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.manageAccounts,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                  if (_showManageAccountsBadge) ...[
                    padx(8),
                    Badge(
                      elevation: 0,
                      badgeContent: Text('!',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      padding: EdgeInsets.all(8),
                      toAnimate: false,
                    )
                  ]
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    bool tall = AppSize(context).tallerThan(AppSize.iphone_se);
    return Container(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Line art background
          OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: SvgPicture.asset(
                  'assets/svg/line_art.svg',
                  width: double.infinity,
                  alignment: orientation == Orientation.landscape
                      ? Alignment.topCenter
                      : Alignment.center,
                  fit: orientation == Orientation.landscape
                      ? BoxFit.fitWidth
                      : BoxFit.contain,
                ),
              );
            },
          ),
          // Large logo and connect button
          Padding(
            // Logo is asymmetric, shift left a bit
            padding: const EdgeInsets.only(right: 21.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                if (tall) ...[
                  _buildLogo(),
                ] else ...[
                  Container(
                      padding: EdgeInsets.only(left: 15),
                      width: 60,
                      height: 48,
                      child: _buildLogo()),
                ],
                pady(tall ? 48 : 16),

                // Connect button
                Padding(
                  // Logo is asymmetric, shift right a bit
                  padding: const EdgeInsets.only(left: 19.0),
                  child: Column(
                    children: [
                      _buildConnectButton(),
                      pady(8),
                      Container(
                        child: _buildStatusMessageLine(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    var image = () {
      return Image.asset('assets/images/connect_logo.png',
          width: 207, height: 186); // match glow image size
    };
    var glowImage = () {
      return Image.asset('assets/images/logo_glow.png',
          width: 207, height: 186);
    };

    var transitionImage = () {
      return ShaderMask(
          shaderCallback: (rect) {
            return _buildTransitionGradient().createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: image());
    };

    /* Attempt to build the glow image dynamically... Need a way to blend.
    var glowLogo = ShaderMask(
      shaderCallback: (rect) {
        return _buildGlowGradient().createShader(rect);
      },
      blendMode: BlendMode.srcATop,
      child: image,
    );

    var blurLogo = ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
      child: image,
    );

    return Stack(
      children: [
        glowLogo,
        blurLogo,
      ],
    );
     */

    switch (_routingState) {
      case OrchidVPNRoutingState.VPNNotConnected:
        return image();
      case OrchidVPNRoutingState.VPNConnecting:
      case OrchidVPNRoutingState.VPNDisconnecting:
      case OrchidVPNRoutingState.VPNConnected:
        return transitionImage();
      case OrchidVPNRoutingState.OrchidConnected:
        return glowImage();
    }
    throw Exception();
  }

  Widget _buildConnectButton() {
    var textColor = Colors.white;
    var bgColor = AppColors.purple_3;
    var gradient;

    String text;
    if (_restarting) {
      text = "Restarting";
    } else {
      switch (_routingState) {
        case OrchidVPNRoutingState.VPNDisconnecting:
          text = s.disconnecting;
          gradient = _buildTransitionGradient();
          break;
        case OrchidVPNRoutingState.VPNConnecting:
          text = s.starting; // vpn is starting
          gradient = _buildTransitionGradient();
          break;
        case OrchidVPNRoutingState.VPNConnected:
          text = s.connecting; // orchid is connecting
          gradient = _buildTransitionGradient();
          break;
        case OrchidVPNRoutingState.VPNNotConnected:
          text = s.connect;
          break;
        case OrchidVPNRoutingState.OrchidConnected:
          textColor = AppColors.purple_3;
          bgColor = AppColors.teal_5;
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

    if (!buttonEnabled) {
      bgColor = AppColors.neutral_4;
    }

    // Rounded flat button supporting gradient with ink effect that works over it
    return FlatButton(
      onPressed: buttonEnabled ? _onConnectButtonPressed : null,
      textColor: Colors.white,
      padding: const EdgeInsets.all(0.0),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24))),
      child: Ink(
        decoration: BoxDecoration(
          color: bgColor,
          gradient: gradient,
          borderRadius: BorderRadius.all(Radius.circular(24.0)),
        ),
        child: Container(
          width: 171,
          height: 48,
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.power_settings_new, color: textColor, size: 24),
              padx(4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Gradient _buildTransitionGradient() {
    return LinearGradient(
        begin: Alignment(0.15, -1.0),
        end: Alignment(0, 1),
        colors: [AppColors.teal_4, AppColors.purple_3],
        tileMode: TileMode.clamp);
  }

  Gradient _buildGlowGradient() {
    return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xffE8DDFD), Color(0xffB88DFC), Color(0xff8C61E1)],
        tileMode: TileMode.clamp);
  }

//  background: linear-gradient(180deg, #E8DDFD 0%, #B88DFC 56.26%, #8C61E1 100%);

  Widget _buildBackgroundGradient() {
    return AnimatedBuilder(
      animation: _connectAnimController,
      builder: (context, child) => Container(
        decoration: BoxDecoration(gradient: _backgroundGradient.value),
      ),
    );
  }

  Widget _buildStatusMessageLine(BuildContext context) {
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

    Color color =
        _showConnectedBackground() ? AppColors.neutral_6 : AppColors.neutral_1;

    return Container(
      height: 32.0,
      alignment: Alignment.bottomCenter,
      child: Text(message,
          textAlign: TextAlign.center,
          style: AppText.connectButtonMessageStyle.copyWith(color: color)),
    );
  }

  /// Called upon a change to Orchid connection state
  void _routingStateChanged(OrchidVPNRoutingState state) async {
    // Fade the background animation in or out based on which direction we are going.
    var fromConnected = _showConnectedBackground();
    var toConnected = _showConnectedBackgroundFor(state);

    if (toConnected && !fromConnected) {
      _connectAnimController.forward().then((_) {});
    }
    if (fromConnected && !toConnected) {
      _connectAnimController.reverse().then((_) {});
    }
    _routingState = state;
    if (mounted) {
      setState(() {});
    }
  }

  /// True if we show the animated connected background for the given state.
  bool _showConnectedBackgroundFor(OrchidVPNRoutingState state) {
    switch (state) {
      case OrchidVPNRoutingState.VPNNotConnected:
      case OrchidVPNRoutingState.VPNConnecting:
      case OrchidVPNRoutingState.VPNConnected:
      case OrchidVPNRoutingState.VPNDisconnecting:
        return false;
      case OrchidVPNRoutingState.OrchidConnected:
        return true;
    }
    throw Exception();
  }

  /// True if we show the animated connected background for the current state.
  bool _showConnectedBackground() {
    return _showConnectedBackgroundFor(_routingState);
  }

  /// Set up animations
  void _initAnimations() {
    _connectAnimController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);

    // The background gradient
    var backgroundGradientDisconnected =
        VerticalLinearGradient(colors: [AppColors.white, AppColors.grey_6]);
    var backgroundGradientConnected = VerticalLinearGradient(
        colors: [AppColors.purple_3, AppColors.purple_1]);
    _backgroundGradient = LinearGradientTween(
            begin: backgroundGradientDisconnected,
            end: backgroundGradientConnected)
        .animate(_connectAnimController);

    // Update the app bar color to match the start of the background gradient
    _backgroundGradient.addListener(() {
      widget.appBarColor.value = _backgroundGradient.value.colors[0];
    });

    // Color tween for icons.
    _iconColor = ColorTween(begin: Color(0xFF3A3149), end: AppColors.white)
        .animate(_connectAnimController);

    // Update the app bar icon color to match the background
    _iconColor.addListener(() {
      widget.iconColor.value = _iconColor.value;
    });
  }

  /// Toggle the current connection state
  void _onConnectButtonPressed() async {
    UserPreferences().routingEnabled.set(!_routingEnabled);

    /*
    switch (_connectionState) {
      case OrchidConnectionState.VPNDisconnecting:
        // Do nothing while we are trying to disconnect
        break;
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.VPNNotConnected:
        UserPreferences().routingEnabled.set(true);
        break;
      case OrchidConnectionState.VPNConnecting:
      case OrchidConnectionState.OrchidConnected:
      case OrchidConnectionState.VPNConnected:
        UserPreferences().routingEnabled.set(false);
        break;
    }*/
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

  // The overall circuit may have changed.
  Future _circuitConfigurationChanged() async {
    var prefs = UserPreferences();
    if (await prefs.guiV0.get()) {
      _hasConfiguredCircuit = (await prefs.getCircuit()).hops.isNotEmpty;
    } else {
      // Determine if there is an active account (valid v1 circuit).
      // (The active account listener will update the detail poller.)
      var accountStore = await AccountStore(discoverAccounts: false).load();
      _hasConfiguredCircuit = accountStore.activeAccount != null;
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

  @override
  void dispose() {
    super.dispose();
    _connectAnimController.dispose();
    _checkAlertsTimer.cancel();
    _subs.dispose();
  }

  S get s {
    return S.of(context);
  }
}
