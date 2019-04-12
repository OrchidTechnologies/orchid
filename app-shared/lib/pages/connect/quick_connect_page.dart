import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_transitions.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/api/notifications.dart';
import 'package:orchid/pages/common/notification_banner.dart';
import 'package:orchid/pages/connect/connect_button.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/pages/common/side_drawer.dart';
import 'package:orchid/pages/common/options_bar.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:orchid/pages/connect/route_info.dart';
import 'package:orchid/pages/onboarding/walkthrough_pages.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/scheduler.dart';

class QuickConnectPage extends StatefulWidget {
  QuickConnectPage({Key key}) : super(key: key);

  @override
  _QuickConnectPageState createState() => _QuickConnectPageState();
}

class _QuickConnectPageState
    extends State<QuickConnectPage> //    with SingleTickerProviderStateMixin {
    with
        TickerProviderStateMixin {
  // Current state reflected by the page, driving color and animation.
  OrchidConnectionState _connectionState = OrchidConnectionState.NotConnected;

  // Interpolates 0-1 on connection
  AnimationController _connectAnimController;

  Animation<Color> _gradientStart;
  Animation<Color> _gradientEnd;
  Animation<Color> _iconColor; // The options bar icons
  Animation<double> _animOpacity; // The background Flare animation

  // This determines whether the intro (slide in) or repeating background animation is shown.
  bool _showIntroAnimation = true;

  @override
  void initState() {
    super.initState();

    checkOnboarding();
    initListeners();
    initAnimations();
  }

  /// Listen for changes in Orchid network status.
  void initListeners() {
    // Monitor connection status
    OrchidAPI().connectionStatus.listen((OrchidConnectionState state) {
      _connectionStateChanged(state);
    });

    // Monitor sync status
    OrchidAPI().syncStatus.listen((OrchidSyncStatus value) {
      _syncStateChanged(value);
    });

    AppNotifications().notification.listen((_) {
      setState(() {}); // Trigger refresh of the UI
    });
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
      _connectAnimController.reverse().then((_) {
        // Reset the animation sequence (intro then loop) for the next connect.
        setState(() {
          _showIntroAnimation = true;
        });
      });
    }

    setState(() {
      _connectionState = state;
    });
  }

  /// Called upon a change to Orchid sync state
  void _syncStateChanged(OrchidSyncStatus value) {
    setState(() {
      switch (value.state) {
        case OrchidSyncState.Complete:
          //_showSyncProgress = false;
          break;
        case OrchidSyncState.Required: // fall through
        case OrchidSyncState.InProgress:
        //_showSyncProgress = true;
      }
    });
  }

  /// True if we show the animated connected background for the given state.
  bool _showConnectedBackgroundFor(OrchidConnectionState state) {
    switch (state) {
      case OrchidConnectionState.NotConnected:
      case OrchidConnectionState.Connecting:
        return false;
      case OrchidConnectionState.Connected:
        return true;
    }
  }

  /// True if we show the animated connected background for the current state.
  bool _showConnectedBackground() {
    return _showConnectedBackgroundFor(_connectionState);
  }

  /// Set up animations
  void initAnimations() {
    _connectAnimController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    //_connectBgAnimController = AnimationController(
    //duration: const Duration(milliseconds: 1800), vsync: this);
    //var _curvedAnim = _connectedStatusAnimationController.drive(CurveTween(curve: Curves.ease));

    _gradientStart = ColorTween(
            begin: AppColors.qc_gradient_start,
            end: AppColors.qc_purple_gradient_start)
        .animate(_connectAnimController);

    _gradientEnd = ColorTween(
            begin: AppColors.qc_gradient_end,
            end: AppColors.qc_purple_gradient_end)
        .animate(_connectAnimController);

    _iconColor = ColorTween(begin: AppColors.purple, end: AppColors.white)
        .animate(_connectAnimController);

    _animOpacity = Tween(begin: 0.0, end: 1.0) // same as controller for now
        .animate(_connectAnimController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(4),
          // Min space with no custom widgets
          child: AppBar(backgroundColor: AppColors.purple, elevation: 0.0)),
      body: buildPageContainer(context),
      drawer: SideDrawer(),
    );
  }

  // The page body holding bacground and options bar
  Widget buildPageContainer(BuildContext context) {
    var connectedAnimation = "assets/flare/Connection_screens_10.flr";
    var animIntro = "connectedIntro";
    var animLoop = "connectedLoop";
    var connectedAnimationName = _showIntroAnimation ? animIntro : animLoop;

    return Stack(
      children: <Widget>[
        // background gradient
        AnimatedBuilder(
          builder: (context, child) => Container(
                  decoration: BoxDecoration(
                gradient: new LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_gradientStart.value, _gradientEnd.value]),
              )),
          animation: _connectAnimController,
        ),

        // bottom map
        Container(
            margin: EdgeInsets.only(bottom: 15.0),
            decoration: BoxDecoration(
                image: new DecorationImage(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    image:
                        new AssetImage('assets/images/world_map_purp.png')))),

        // The background animation
        Visibility(
          visible: _showConnectedBackground(),
          child: AnimatedBuilder(
            builder: (context, child) => Opacity(
                child: Container(
                  height: 370,
                  child: FlareActor(
                    connectedAnimation,
                    //isPaused: true,
                    fit: BoxFit.none,
                    animation: connectedAnimationName,
                    callback: (name) {
                      if (name == animIntro) {
                        setState(() {
                          _showIntroAnimation = false;
                        });
                      }
                    },
                  ),
                ),
                opacity: _animOpacity.value),
            animation: _connectAnimController,
          ),
        ),

        // The page content including the button title, button, and route info when connected.
        buildPageContent(context),

        // Options bar with optional notification banner
        Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: <Widget>[
              // The optional notification banner
              AnimatedSwitcher(
                child: NotificationBannerFactory.current() ?? Container(),
                transitionBuilder: (widget, anim) {
                  var tween =
                      Tween<Offset>(begin: Offset(0.0, -1.0), end: Offset.zero)
                          .animate(anim);
                  return SlideTransition(position: tween, child: widget);
                },
                duration: Duration(milliseconds: 200),
              ),
              // The options bar. (Animated builder allows the color transition).
              AnimatedBuilder(
                builder: (context, child) {
                  // https://stackoverflow.com/questions/45424621/inkwell-not-showing-ripple-effect
                  //Material
                  return OptionsBar(
                    color: _iconColor.value,
                    menuPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    morePressed: () {},
                  );
                },
                animation: _connectAnimController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The page content including the button title, button, and route info when connected.
  Widget buildPageContent(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var buttonY = screenSize.height * 0.34;
    var buttonImageHeight = 142;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(
                  top: buttonY - buttonImageHeight * 1.05,
                  child: _buildStatusMessage(context)),
              Positioned(
                top: -screenSize.width / 2 + buttonY,
                width: screenSize.width,
                height: screenSize.width,
                child: ConnectButton(
                  //key: GlobalKey(),
                  connectionStatus: OrchidAPI().connectionStatus,
                  enabledStatus: BehaviorSubject.seeded(true),
                  // stand-in for later
                  onConnectButtonPressed: _onConnectButtonPressed,
                  onRerouteButtonPressed: _rerouteButtonPressed,
                ),
              ),
              Positioned(
                top: buttonY + buttonImageHeight * 1.11,
                child: Visibility(
                    visible: _showConnectedBackground(),
                    //visible: false,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: RouteInfo()),
              ),
            ],
          ),
    );
  }

  Widget _buildStatusMessage(BuildContext context) {
    // Localize
    Map<OrchidConnectionState, String> connectionStateMessage = {
      OrchidConnectionState.NotConnected: 'Push to connect.',
      OrchidConnectionState.Connecting: 'Connecting...',
      //OrchidConnectionState.Connected: 'Orchid is running! 🙌',
      OrchidConnectionState.Connected: 'Orchid is running!',
    };

    String message = connectionStateMessage[_connectionState];
    Color color = (_connectionState == OrchidConnectionState.Connected
        ? const Color(0xffe7eaf4) // light
        : const Color(0xff3a3149)); // dark

    return Container(
      // Note: the emoji changes the baseline so we give this a couple of pixels
      // Note: of extra hieght and bottom align it.
      height: 18.0,
      alignment: Alignment.bottomCenter,
      child: Text(message,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w400,
              fontFamily: "Roboto",
              fontStyle: FontStyle.normal,
              fontSize: 12.0)),
    );
  }

  void _onConnectButtonPressed() {
    // Toggle the current connection state
    switch (_connectionState) {
      case OrchidConnectionState.NotConnected:
        OrchidAPI().setConnected(true);
        break;
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.Connected:
        OrchidAPI().setConnected(false);
        break;
    }
  }

  void _rerouteButtonPressed() {
    OrchidAPI().reroute();
  }

  void checkOnboarding() {
    UserPreferences()
        .getWalkthroughCompleted()
        .then((bool walkthroughCompleted) {
      if (!(walkthroughCompleted ?? false)) {
        Navigator.push(
            context, AppTransitions.downToUpTransition(WalkthroughPages()));
      }
    });
  }
}
