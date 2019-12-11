import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/api/notifications.dart';
import 'package:orchid/pages/common/gradients.dart';
import 'package:orchid/pages/connect/connect_button.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:rxdart/rxdart.dart';
import 'connect_world_map.dart';

/// The main page containing the connect button.
class QuickConnectPage extends StatefulWidget {
  static bool allowScrolling = false;

  QuickConnectPage({Key key}) : super(key: key);

  @override
  _QuickConnectPageState createState() => _QuickConnectPageState();
}

class _QuickConnectPageState
    extends State<QuickConnectPage> // with SingleTickerProviderStateMixin {
    with
        TickerProviderStateMixin //, AutomaticKeepAliveClientMixin // This breaks things unexpectedly.
{
  // Current state reflected by the page, driving color and animation.
  OrchidConnectionState _connectionState = OrchidConnectionState.NotConnected;

  // Animation controller for transitioning to the connected state
  AnimationController _connectAnimController;

  // Animations driven by the connected state
  Animation<LinearGradient> _backgroundGradient;
  Animation<LinearGradient> _mapGradient;
  Animation<double> _animOpacity; // The background Flare animation

  // This determines whether the intro (slide in) or repeating background animation is shown.
  bool _showIntroAnimation = true;

  ScrollController _scrollController = ScrollController();

  List<StreamSubscription> _rxSubscriptions = List();

  @override
  void initState() {
    super.initState();
    //AppOnboarding().showPageIfNeeded(context);
    _initListeners();
    _initAnimations();
  }

  @override
  Widget build(BuildContext context) {
    return buildPageContainer(context);
  }

  /// The page background and (if standalone, options bar).
  /// Note: Some opportunity to factor out widgets below but it wouldn't really
  /// Note: help much in this context.
  Widget buildPageContainer(BuildContext context) {
    return Stack(
      children: <Widget>[
        // background gradient
        _buildBackgroundGradient(),

        // Fixed position for the flare animation on scrolling.
        // The connected state background Flare animation
        //_buildPositionedConnectedAnimation(),

        // The background map and route visualization
        _buildPositionedMap(),

        // The page content including the button title, button, and route info when connected.
        _buildScrollablePageContent(),

        // Options bar with optional notification banner
        //ConnectOptionsBar(iconColor: _iconColor, connectAnimController: _connectAnimController),
      ],
    );
  }

  /// The page content including the button title, button, and route info when connected.
  Widget _buildScrollablePageContent() {
    var screenSize = MediaQuery.of(context).size;
    var statusBarTop = MediaQuery.of(context).padding.top;
    var buttonImageHeight = 142; // The button image height

    // The button widget fits the width allowing for the pulsing animation.
    var buttonSize = screenSize.width;

    // Position for the center of the button
    var buttonY = screenSize.height * 0.29;

    // How much of the button image should remain visible when fully scrolled up.
    var buttonRemaining = 15;

    // Calculate the screen height based on the desired button position.
    var scrollHeight = screenSize.height -
        statusBarTop +
        buttonY +
        buttonImageHeight / 2 -
        buttonRemaining;

    return SingleChildScrollView(
      physics: QuickConnectPage.allowScrolling
          ? null
          : const NeverScrollableScrollPhysics(),
      controller: _scrollController,
      child: Container(
        height: scrollHeight,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: <Widget>[
            // The status message
            Positioned(
                top: buttonY - buttonImageHeight * 1.05,
                child: _buildStatusMessage(context)),

            // Scroll the flare anim with the content
            // The connected state background Flare animation
            _buildPositionedConnectedAnimation(),

            // The large connect button
            Positioned(
              top: buttonY - buttonSize / 2,
              width: buttonSize,
              height: buttonSize,
              child: ConnectButton(
                connectionStatus: OrchidAPI().connectionStatus,
                enabledStatus: BehaviorSubject.seeded(true),
                onConnectButtonPressed: _onConnectButtonPressed,
                onRerouteButtonPressed: _rerouteButtonPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the map and position it based on scroll position.
  Widget _buildPositionedMap() {
    // Size the map size to fit the screen initially.
    Size screenSize = MediaQuery.of(context).size;
    var mapHorizontalMargins = 5;
    var mapStartHeight = (screenSize.width - mapHorizontalMargins * 2) /
        ConnectWorldMap.worldMapImage.aspectRatio;

    // The map center starting vertical position as fraction of screen height.
    double mapStartPosition = 0.58;
    // The map center ending vertical position as fraction of screen height.
    double mapEndPosition = 0.5;
    // The zoom at min scroll
    double mapStartZoom = 1.1;
    // The zoom at max scroll
    double mapEndZoom = 2.5;

    // Animated builder that responds to scrolling or connection state transitions
    return AnimatedBuilder(
      animation: Listenable.merge([_scrollController, _connectAnimController]),
      builder: (BuildContext context, Widget child) {
        double mapWidth = screenSize.width;
        double mapHeight = max(
            0,
            mapStartHeight *
                mapStartZoom *
                (1 + (mapEndZoom - 1) * scrollFraction));
        double mapPosition = mapStartPosition +
            scrollFraction * (mapEndPosition - mapStartPosition);

        // The interpolated map vertical position.
        // Note: this should probably subtract the safe area margins.
        double mapTop = mapPosition * screenSize.height - mapHeight / 2;

        var locations = (OrchidAPI().routeStatus.value ?? OrchidRoute([]))
            .nodes
            .map((node) => node.location)
            .toList();
        return Positioned(
          top: mapTop,
          child: ConnectWorldMap(
            locations: locations,
            mapGradient: _mapGradient.value,
            width: mapWidth,
            height: mapHeight,
            showOverlay: _connectionState == OrchidConnectionState.Connected,
          ),
        );
      },
    );
  }

  /// Get the fraction of the total scroll extent represented by the current
  /// scroll offset (0.0 - 1.0).
  double get scrollFraction {
    double scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0;
    double maxScrollExtent = (_scrollController.hasClients
            ? _scrollController.position.maxScrollExtent
            : double.infinity) ??
        double.infinity;
    double scrollFrac = scrollOffset / maxScrollExtent;
    return scrollFrac;
  }

  AnimatedBuilder _buildBackgroundGradient() {
    return AnimatedBuilder(
      animation: _connectAnimController,
      builder: (context, child) => Container(
          decoration: BoxDecoration(gradient: _backgroundGradient.value)),
    );
  }

  /// The connected state background Flare animation
  Widget _buildPositionedConnectedAnimation() {
    String connectedAnimation = "assets/flare/Connection_screens.flr";
    String connectedAnimationIntroName = "connectedIntro";
    String connectedAnimationLoopName = "connectedLoop";
    String connectedAnimationName = _showIntroAnimation
        ? connectedAnimationIntroName
        : connectedAnimationLoopName;

    // Calculate the animation size and position
    double connectedAnimationAspectRatio = 360.0 / 340.0; // w/h
    double connectedAnimationPosition =
        0.34; // vertical screen height fraction of center
    Size screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_connectAnimController, _scrollController]),
      builder: (context, child) {
        Size animationSize = Size(
            screenSize.width,
            // fixed size on scroll
            screenSize.width / connectedAnimationAspectRatio
            // grow with scroll
            //max(0, screenSize.width / connectedAnimationAspectRatio - _scrollController.offset)
            );
        double animationTop = screenSize.height * connectedAnimationPosition -
            animationSize.height / 2;

        return Visibility(
          visible: _showConnectedBackground(),
          child: Positioned(
            top: animationTop,
            child: Opacity(
              // opacity from connected animation only
              opacity: _animOpacity.value,

              // opacity changes on scroll
              //opacity: _animOpacity.value *
              //min(1.0, max(0, 1.0 - scrollFraction * 0.6)),

              child: Container(
                width: animationSize.width,
                height: animationSize.height,
                child: FlareActor(
                  connectedAnimation,
                  fit: BoxFit.fitHeight,
                  animation: connectedAnimationName,
                  callback: (name) {
                    if (name == connectedAnimationIntroName) {
                      setState(() {
                        _showIntroAnimation = false;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage(BuildContext context) {
    // Localize
    String message;
    switch (_connectionState) {
      case OrchidConnectionState.Disconnecting:
        message = 'Disonnecting...';
        break;
      case OrchidConnectionState.Connecting:
        message = 'Connecting...';
        break;
    case OrchidConnectionState.Invalid:
    case OrchidConnectionState.NotConnected:
        message = 'Push to connect.';
        break;
      case OrchidConnectionState.Connected:
        message = 'Orchid is running!';
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

  /// Listen for changes in Orchid network status.
  void _initListeners() {
    OrchidAPI().logger().write("Connect Page: Init listeners...");

    // Monitor VPN permission status
    /*
    _rxSubscriptions
        .add(OrchidAPI().vpnPermissionStatus.listen((bool installed) {
      OrchidAPI().logger().write("VPN Perm status changed: $installed");
      if (!installed) {
        // TODO: Showing this vertical transition breaks the (completely unrelated) reorderable
        // TODO: list view in the circuit builder page???
        //var route = AppTransitions.downToUpTransition(
        //OnboardingVPNPermissionPage(allowSkip: false));
        //Navigator.push(context, route);
        Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    OnboardingVPNPermissionPage(allowSkip: false)));
      }
    }));
     */

    // Monitor connection status
    _rxSubscriptions
        .add(OrchidAPI().connectionStatus.listen((OrchidConnectionState state) {
      OrchidAPI()
          .logger()
          .write("[connect page] Connection status changed: $state");
      _connectionStateChanged(state);
    }));

    // Monitor sync status
    _rxSubscriptions
        .add(OrchidAPI().syncStatus.listen((OrchidSyncStatus value) {
      _syncStateChanged(value);
    }));

    _rxSubscriptions.add(AppNotifications().notification.listen((_) {
      setState(() {}); // Trigger refresh of the UI
    }));
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

    _connectionState = state;
    if (mounted) {
      setState(() {});
    }
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
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.NotConnected:
      case OrchidConnectionState.Connecting:
        return false;
      case OrchidConnectionState.Connected:
      case OrchidConnectionState.Disconnecting:
        return true;
    }
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
        VerticalLinearGradient(colors: [AppColors.grey_7, AppColors.grey_6]);
    var backgroundGradientConnected = VerticalLinearGradient(
        colors: [AppColors.purple_2, AppColors.purple_1]);
    _backgroundGradient = LinearGradientTween(
            begin: backgroundGradientDisconnected,
            end: backgroundGradientConnected)
        .animate(_connectAnimController);

    // The map gradient
    var mapGradientDisconnected = VerticalLinearGradient(colors: [
      AppColors.grey_5.withOpacity(0.25),
      AppColors.grey_4.withOpacity(0.25)
    ]);
    var mapGradientConnected = VerticalLinearGradient(
        colors: [AppColors.purple_5, AppColors.purple_3]);
    _mapGradient = LinearGradientTween(
            begin: mapGradientDisconnected, end: mapGradientConnected)
        .animate(_connectAnimController);

    // Color tween for icons.
    //_iconColor = ColorTween(begin: AppColors.purple, end: AppColors.white)
    //.animate(_connectAnimController);

    _animOpacity = Tween(begin: 0.0, end: 1.0) // same as controller for now
        .animate(_connectAnimController);

    // If we're already running cancel the intro animation.
    if (OrchidAPI().connectionStatus.value == OrchidConnectionState.Connected) {
      _showIntroAnimation = false;
    }
  }

  void _onConnectButtonPressed() {
    // Toggle the current connection state
    switch (_connectionState) {
      case OrchidConnectionState.Disconnecting:
        // Do nothing while we are trying to disconnect
        break;
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.NotConnected:
        _checkPermissionAndEnableConnection();
        break;
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.Connected:
        _disableConnection();
        break;
    }
  }

  // duplicates code in monitoring_page
  void _checkPermissionAndEnableConnection() {
    UserPreferences().setDesiredVPNState(true);
    // Get the most recent status, blocking if needed.
    _rxSubscriptions
        .add(OrchidAPI().vpnPermissionStatus.take(1).listen((installed) async {
      debugPrint("vpn: current perm: $installed");
      if (installed) {
        debugPrint("vpn: already installed");
        OrchidAPI().setConnected(true);
        setState(() {});
      } else {
        bool ok = await OrchidAPI().requestVPNPermission();
        if (ok) {
          debugPrint("vpn: user chose to install");
          // Note: It appears that trying to enable the connection too quickly
          // Note: after installing the vpn permission / config fails.
          // Note: Introducing a short artificial delay.
          Future.delayed(Duration(milliseconds: 500)).then((_) {
            OrchidAPI().setConnected(true);
          });
        } else {
          debugPrint("vpn: user skipped");
        }
      }
    }));
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
    _rxSubscriptions.forEach((sub) {
      sub.cancel();
    });
  }

//@override bool get wantKeepAlive => true;
}
