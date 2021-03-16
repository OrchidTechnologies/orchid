import 'dart:async';
import 'dart:ui';
import 'package:badges/badges.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/account_manager/account_store.dart';
import 'package:orchid/pages/app_sizes.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/api/notifications.dart';
import 'package:orchid/pages/circuit/model/orchid_hop.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/gradients.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/connect/release.dart';
import 'package:orchid/pages/connect/welcome_panel.dart';

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
  // Current state reflected by the page, driving color and animation.
  OrchidConnectionState _connectionState =
      OrchidConnectionState.VPNNotConnected;

  // Animation controller for transitioning to the connected state
  AnimationController _connectAnimController;

  //AnimationController _highlightAnimationController;

  // Animations driven by the connected state
  Animation<LinearGradient> _backgroundGradient;
  Animation<Color> _iconColor;

  bool _hasConfiguredCircuit = false;

  // TODO:
  // bool get _showWelcomePane => !_hasConfiguredCircuit;
  bool get _showWelcomePane => false;

  bool _enableConnectWithoutHops = false;

  Timer _checkHopAlertsTimer;
  bool _showProfileBadge = false;

  List<StreamSubscription> _subs = [];

  bool _guiV1 = true;

  @override
  void initState() {
    super.initState();
    _initListeners();
    _initAnimations();

    _checkHopAlertsTimer =
        Timer.periodic(Duration(seconds: 30), _checkHopAlerts);
    _checkHopAlerts(null);

    _releaseVersionCheck();
  }

  // TODO: This needs to handle v1 configs
  /// Check Orchid Hop's lottery pot for alert conditions and reflect that in the
  /// manage profile button.
  /// Note: This should really be merged with the logic from circuit page that does
  /// Note: the same, however this requires a unique id for hops. Refactor at that time
  /// Note: by hoisting the logic here and passing the data to circuit page.
  void _checkHopAlerts(timer) async {
    // TODO: don't show badges when in V1 UI mode
    if (!(await UserPreferences().guiV0.get())) {
      if (mounted) {
        setState(() {
          _showProfileBadge = false;
        });
      }
      return;
    }

    var hops = (await UserPreferences().getCircuit()).hops;
    var keys = await UserPreferences().getKeys();
    bool showBadge = false;
    for (var hop in hops) {
      if (hop is OrchidHop) {
        try {
          var pot = await OrchidEthereumV0.getLotteryPot(
              hop.funder, hop.getSigner(keys));
          var ticketValue = await MarketConditionsV0.getMaxTicketValueV0(pot);
          if (ticketValue.lteZero()) {
            showBadge = true;
          }
        } catch (err) {
          log("Error fetching lottery pot: err");
        }
      }
    }
    if (mounted) {
      setState(() {
        _showProfileBadge = showBadge;
      });
    }
  }

  /// Listen for changes in Orchid network status.
  void _initListeners() {
    log('Connect Page: Init listeners...');

    // Monitor VPN permission status
    /*
    _rxSubscriptions
        .add(OrchidAPI().vpnPermissionStatus.listen((bool installed) {
      OrchidAPI().logger().write('VPN Perm status changed: $installed');
      if (!installed) {
        //var route = AppTransitions.downToUpTransition(
        //OnboardingVPNPermissionPage(allowSkip: false));
        //Navigator.push(context, route);
        Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    OnboardingVPNPermissionPage(allowSkip: false)));
      }
    }));
     */

    // Monitor connection status
    _subs
        .add(OrchidAPI().connectionStatus.listen((OrchidConnectionState state) {
      log('[connect page] Connection status changed: $state');
      _connectionStateChanged(state);
    }));
    
    // TEST:
    Future.delayed(Duration(seconds: 3)).then((_) {
      _connectionStateChanged(OrchidConnectionState.OrchidConnected);
    });

    _subs.add(AppNotifications().notification.listen((_) {
      setState(() {}); // Trigger refresh of the UI
    }));

    // TODO: The circuit really should be observable directly via OrchidAPI
    _subs.add(OrchidAPI().circuitConfigurationChanged.listen((value) {
      _updateCircuitStatus();
      _checkHopAlerts(null); // refresh alert status
    }));

    _subs.add(UserPreferences().allowNoHopVPN.stream().listen((value) {
      setState(() {
        _enableConnectWithoutHops = value;
      });
    }));

    // Monitor changes in the UI version preference
    _subs.add(UserPreferences().guiV0.stream().listen((guiV0) {
      _guiV1 = !guiV0;
      // TEST:
      // _guiV1 = false;
      _checkHopAlerts(null);
      _updateCircuitStatus();
      setState(() {}); // Refresh UI
    }));
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
              //child: Container(color: Colors.orange, width: 50, height: 50),
            ),
          )
      ],
    );
  }

  /// The page content including the button title, button, and route info when connected.
  Widget _buildPageContent() {
    return Column(
      children: <Widget>[
        // Line art background, logo, and connect button
        Expanded(
          flex: 12,
          child: _buildCenterControls(),
        ),

        if (_guiV1) Spacer(flex: 1),
        if (_guiV1)
          ConnectStatusPanel(darkBackground: _showConnectedBackground()),

        Spacer(flex: 1),
        _buildManageAccountsButton(),

        pady(24),
        _buildStatusMessage(context),

        Spacer(flex: 2),
      ],
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
                _checkHopAlerts(null);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Manage Accounts",
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                  if (_showProfileBadge) ...[
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
                pady(48),

//              if (_connectionState == OrchidConnectionState.Connecting ||
//                  _connectionState == OrchidConnectionState.Disconnecting)
//                AnimatedBuilder(
//                    animation: _highlightAnimationController,
//                    builder: (context, snapshot) {
//                      return _buildConnectButton();
//                    })
//              else

                // Connect button
                Padding(
                  // Logo is asymmetric, shift right a bit
                  padding: const EdgeInsets.only(left: 19.0),
                  child: _buildConnectButton(),
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

    switch (_connectionState) {
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.VPNNotConnected:
        return image();
      case OrchidConnectionState.VPNConnecting:
      case OrchidConnectionState.VPNDisconnecting:
      case OrchidConnectionState.VPNConnected:
        return transitionImage();
      case OrchidConnectionState.OrchidConnected:
        return glowImage();
    }
    throw Exception();
  }

  Widget _buildConnectButton() {
    var textColor = Colors.white;
    var bgColor = AppColors.purple_3;
    var gradient;
    String text;
    switch (_connectionState) {
      case OrchidConnectionState.VPNDisconnecting:
        text = s.disconnecting;
        gradient = _buildTransitionGradient();
        break;
      case OrchidConnectionState.VPNConnecting:
        text = s.starting; // vpn is starting
        gradient = _buildTransitionGradient();
        break;
      case OrchidConnectionState.VPNConnected:
        text = s.connecting; // orchid is connecting
        gradient = _buildTransitionGradient();
        break;
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.VPNNotConnected:
        text = s.connect;
        break;
      case OrchidConnectionState.OrchidConnected:
        textColor = AppColors.purple_3;
        bgColor = AppColors.teal_5;
        text = s.disconnect;
    }

    bool buttonEnabled =
        // Enabled when there is a circuit (or overridden for traffic monitoring)
        (_hasConfiguredCircuit || _enableConnectWithoutHops) ||
            // Enabled if we are already connected (corner case of changed config while connected).
            _connectionState == OrchidConnectionState.VPNConnecting ||
            _connectionState == OrchidConnectionState.VPNConnected ||
            _connectionState == OrchidConnectionState.OrchidConnected;

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
//        begin: Alignment(0, -1 + _highlightAnimationController.value ?? 0),
//        end: Alignment(0, 1 + _highlightAnimationController.value ?? 0),
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

  // TODO: This will be driven by the tunnel status messages when available
  Widget _buildStatusMessage(BuildContext context) {
    // Localize
    String message;
    switch (_connectionState) {
      case OrchidConnectionState.VPNDisconnecting:
        message = s.orchidDisconnecting;
        break;
      case OrchidConnectionState.VPNConnecting:
        message = s.orchidConnecting;
        break;
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.VPNNotConnected:
        message = s.pushToConnect;
        break;
      case OrchidConnectionState.VPNConnected:
        message = s.orchidIsStarting;
        break;
      case OrchidConnectionState.OrchidConnected:
        message = s.orchidIsRunning;
    }

    Color color =
        _showConnectedBackground() ? AppColors.neutral_6 : AppColors.neutral_1;

    return Container(
      // Note: the emoji changes the baseline so we give this a couple of pixels
      // Note: of extra hieght and bottom align it.
      height: 32.0,
      alignment: Alignment.bottomCenter,
      child: Text(message,
          textAlign: TextAlign.center,
          style: AppText.connectButtonMessageStyle.copyWith(color: color)),
    );
  }

  void _updateCircuitStatus() async {
    var prefs = UserPreferences();
    if (await prefs.guiV0.get()) {
      _hasConfiguredCircuit = (await prefs.getCircuit()).hops.isNotEmpty;
    } else {
      var accountStore = await AccountStore(discoverAccounts: false).load();
      _hasConfiguredCircuit = accountStore.activeAccount != null;
    }
    setState(() {});
  }

  /// Called upon a change to Orchid connection state
  void _connectionStateChanged(OrchidConnectionState state) {
    // Fade the background animation in or out based on which direction we are going.
    var fromConnected = _showConnectedBackground();
    var toConnected = _showConnectedBackgroundFor(state);

    if (toConnected && !fromConnected) {
      _connectAnimController.forward().then((_) {});
    }
    if (fromConnected && !toConnected) {
      _connectAnimController.reverse().then((_) {});
    }
    _connectionState = state;
    if (mounted) {
      setState(() {});
    }
  }

  /// True if we show the animated connected background for the given state.
  bool _showConnectedBackgroundFor(OrchidConnectionState state) {
    switch (state) {
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.VPNNotConnected:
      case OrchidConnectionState.VPNConnecting:
      case OrchidConnectionState.VPNConnected:
      case OrchidConnectionState.VPNDisconnecting:
        return false;
      case OrchidConnectionState.OrchidConnected:
        return true;
    }
    throw Exception();
  }

  /// True if we show the animated connected background for the current state.
  bool _showConnectedBackground() {
    return _showConnectedBackgroundFor(_connectionState);
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

//    _highlightAnimationController = AnimationController(
//        vsync: this, duration: Duration(milliseconds: 4000));
//    _highlightAnimationController.repeat();
  }

  void _onConnectButtonPressed() {
    // Toggle the current connection state
    switch (_connectionState) {
      case OrchidConnectionState.VPNDisconnecting:
        // Do nothing while we are trying to disconnect
        break;
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.VPNNotConnected:
        _checkPermissionAndEnableConnection();
        break;
      case OrchidConnectionState.VPNConnecting:
      case OrchidConnectionState.OrchidConnected:
      case OrchidConnectionState.VPNConnected:
        _disableConnection();
        break;
    }
  }

  // duplicates code in monitoring_page
  void _checkPermissionAndEnableConnection() {
    UserPreferences().setDesiredVPNState(true);
    // Get the most recent status, blocking if needed.
    _subs.add(OrchidAPI().vpnPermissionStatus.take(1).listen((installed) async {
      log('vpn: current perm: $installed');
      if (installed) {
        log('vpn: already installed');
        OrchidAPI().setConnected(true);
        setState(() {});
      } else {
        bool ok = await OrchidAPI().requestVPNPermission();
        if (ok) {
          log('vpn: user chose to install');
          // Note: It appears that trying to enable the connection too quickly
          // Note: after installing the vpn permission / config fails.
          // Note: Introducing a short artificial delay.
          Future.delayed(Duration(milliseconds: 500)).then((_) {
            OrchidAPI().setConnected(true);
          });
        } else {
          log('vpn: user skipped');
        }
      }
    }));
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
      title: "New Release",
      bodyText: Release.message,
    );
  }

  void _disableConnection() {
    UserPreferences().setDesiredVPNState(false);
    OrchidAPI().setConnected(false);
  }

  void _rerouteButtonPressed() {
    OrchidAPI().reroute();
  }

  @override
  void dispose() {
    super.dispose();
    _connectAnimController.dispose();
//    _highlightAnimationController.dispose();
    _checkHopAlertsTimer.cancel();
    _subs.forEach((sub) {
      sub.cancel();
    });
  }

  S get s {
    return S.of(context);
  }
}
