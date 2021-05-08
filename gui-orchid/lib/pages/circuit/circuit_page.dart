import 'dart:async';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_eth_v0.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_market_v0.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/common/app_reorderable_list.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/link_text.dart';
import 'package:orchid/common/titled_page_base.dart';
import 'package:orchid/common/wrapped_switch.dart';
import 'package:orchid/pages/circuit/config_change_dialogs.dart';

import '../../common/app_gradients.dart';
import '../../common/app_text.dart';
import 'add_hop_page.dart';
import 'hop_editor.dart';
import 'hop_tile.dart';
import 'model/circuit.dart';
import 'model/circuit_hop.dart';
import 'model/orchid_hop.dart';

class CircuitPage extends StatefulWidget {
  // TODO: Remove if unused
  final WrappedSwitchController switchController;

  // Note: This performs a behavior like the iOSContacts App create flow for the
  // Note: add hop action, revealing the already pushed hop editor upon completing
  // Note: the add flow.
  static var iOSContactsStyleAddHopBehavior = false;

  CircuitPage({Key key, this.switchController}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new CircuitPageState();
  }
}

// TODO: This class contains switch logic for activating the VPN that is not currently
// TODO: used.  If this remains the case remove it.
class CircuitPageState extends State<CircuitPage>
    with TickerProviderStateMixin {
  List<StreamSubscription> _rxSubs = [];
  List<UniqueHop> _hops;

  // Master timeline for connect animation
  AnimationController _masterConnectAnimController;

  // The duck into hole animation
  AnimationController _bunnyDuckAnimController;

  // Animations driven by the master timelines
  Animation<double> _connectAnimController;
  Animation<double> _bunnyExitAnim;
  Animation<double> _bunnyDuckAnimation;
  Animation<double> _bunnyEnterAnim;
  Animation<double> _holeTransformAnim;
  Animation<Color> _hopColorTween;

  // Anim params
  int _fadeAnimTime = 200;
  int _connectAnimTime = 1200;
  DateTime _lastInteractionTime;
  Timer _bunnyDuckTimer;

  //bool vpnSwitchInstructionsViewed = false;
  bool _dialogInProgress = false; // ?

  @override
  void initState() {
    super.initState();
    // Test Localization
    //S.load(Locale('zh', 'CN'));
    initStateAsync();
    initAnimations();
  }

  Timer _checkBalancesTimer;

  void initStateAsync() async {
    // Hook up to the provided vpn switch
    //widget.switchController.onChange = _connectSwitchChanged;

    // Set the initial state of the vpn switch based on the user pref.
    // Note: By design the switch on this page does not track or respond to the
    // Note: dynamic connection state but instead reflects the user pref.
    // Note: See `monitoring_page.dart` or `legacy_connect_page` for controls that track the
    // Note: system connection status.
    _switchOn = await UserPreferences().getDesiredVPNState();

    //vpnSwitchInstructionsViewed = await UserPreferences().getVPNSwitchInstructionsViewed();

    OrchidAPI().circuitConfigurationChanged.listen((_) {
      _updateCircuit();
    });

    //_checkFirstLaunch();
    _checkBalancesTimer =
        Timer.periodic(Duration(seconds: 30), _checkHopAlerts);
    _checkHopAlerts(null);
  }

  static Map<int, bool> _showHopAlert = Map();

  /// Check each Orchid Hop's lottery pot for alert conditions.
  void _checkHopAlerts(timer) async {
    if (_hops == null) {
      return;
    }
    // Check for hops that cannot write tickets.
    List<StoredEthereumKey> keys = await UserPreferences().getKeys();
    for (var uniqueHop in _hops) {
      CircuitHop hop = uniqueHop.hop;
      if (hop is OrchidHop) {
        try {
          var pot = await OrchidEthereumV0.getLotteryPot(
              hop.funder, hop.getSigner(keys));
          var ticketValue = await MarketConditionsV0.getMaxTicketValueV0(pot);
          _showHopAlert[uniqueHop.contentHash] = ticketValue.lteZero();
        } catch (err, stack) {
          log("Error checking ticket value: $err\n$stack");
        }
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  /*
  void _checkFirstLaunch() async {
    if (!await UserPreferences().getFirstLaunchInstructionsViewed()) {
      _showWelcomeDialog();
      UserPreferences().setFirstLaunchInstructionsViewed(true);
    }
  }*/

  void _updateCircuit() async {
    var circuit = await UserPreferences().getCircuit();
    if (mounted) {
      setState(() {
        var keyBase = DateTime.now().millisecondsSinceEpoch;
        // Wrap the hops with a locally unique id for the UI
        _hops = UniqueHop.wrap(circuit.hops, keyBase);
      });

      // Set the correct animation states for the connection status
      // Note: We cannot properly do this until we know if we have hops!
      log('init state, setting initial connection state');
      _connectionStateChanged(OrchidAPI().connectionStatus.value,
          animated: false);
    }
    _checkHopAlerts(null); // refresh alert status
  }

  void initAnimations() {
    _masterConnectAnimController = AnimationController(
        duration: Duration(milliseconds: _connectAnimTime), vsync: this);

    _bunnyDuckAnimController =
        AnimationController(duration: Duration(milliseconds: 300), vsync: this);

    _connectAnimController = CurvedAnimation(
        parent: _masterConnectAnimController, curve: Interval(0, 1.0));

    _bunnyExitAnim = CurvedAnimation(
        parent: _connectAnimController,
        curve: Interval(0, 0.4, curve: Curves.easeInOutExpo));

    _bunnyDuckAnimation = CurvedAnimation(
        parent: _bunnyDuckAnimController, curve: Curves.easeOut);

    _holeTransformAnim = CurvedAnimation(
        parent: _connectAnimController,
        curve: Interval(0.4, 0.5, curve: Curves.easeIn));

    _bunnyEnterAnim = CurvedAnimation(
        parent: _connectAnimController,
        curve: Interval(0.6, 1.0, curve: Curves.easeInOutExpo));

    _hopColorTween =
        ColorTween(begin: Color(0xffa29ec0), end: Color(0xff8c61e1))
            .animate(_connectAnimController);

    _bunnyDuckTimer = Timer.periodic(Duration(seconds: 1), _checkBunny);

    // Update the UI on connection status changes
    _rxSubs.add(OrchidAPI().connectionStatus.listen(_connectionStateChanged));
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      lightTheme: true,
      title: S.of(context).manageProfile,
      decoration: BoxDecoration(),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return NotificationListener(
      onNotification: (notif) {
        _userInteraction();
        return false;
      },
      child: GestureDetector(
        onTapDown: (_) {
          _userInteraction();
        },
        child: Container(
          decoration: BoxDecoration(gradient: AppGradients.basicGradient),
          // hidden until hops loaded
          child: Visibility(
              //visible: _hops != null,
              visible: true,
              replacement: Container(),
              child: _buildHopList()),
        ),
      ),
    );
  }

  bool _showEnableVPNInstruction() {
    return false;
    //Note: this instruction follows the switch, not the connected status
    //return !vpnSwitchInstructionsViewed && _hasHops() && !_switchOn;
  }

  Widget _buildHopList() {
    // Note: this view needs to be full screen vertical in order to scroll off-edge properly.
    return AppReorderableListView(
        header: Column(
          children: <Widget>[
            AnimatedCrossFade(
              duration: Duration(milliseconds: _fadeAnimTime),
              crossFadeState: _showEnableVPNInstruction()
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildEnableVPNInstruction(),
              secondChild: pady(16),
            ),
            if (AppSize(context).tallerThan(AppSize.iphone_12_max)) pady(64),
            AnimatedBuilder(
                animation: Listenable.merge(
                    [_connectAnimController, _bunnyDuckAnimation]),
                builder: (BuildContext context, Widget child) {
                  return _buildStartTile();
                }),
            _buildStatusTile(),
            HopTile.buildFlowDivider(),
          ],
        ),
        children: (_hops ?? []).map((uniqueHop) {
          return _buildDismissableHopTile(uniqueHop);
        }).toList(),
        footer: Column(
          children: <Widget>[
            _buildNewHopTile(),
            //if (!_hasHops()) _buildFirstHopInstruction(),
            if (!_hasHops()) pady(16),
            HopTile.buildFlowDivider(
                padding: EdgeInsets.only(top: _hasHops() ? 16 : 2, bottom: 10)),
            AnimatedBuilder(
                animation: _connectAnimController,
                builder: (BuildContext context, Widget child) {
                  return _buildEndTile();
                }),
            _buildDeletedHopsLink(),
            pady(32)
          ],
        ),
        onReorder: _onReorder);
  }

  // The starting (top) tile in the hop flow
  Widget _buildStartTile() {
    var bunnyWidth = 47.0;
    var bunnyHeight = 75.0;
    var clipOvalWidth = 130.0;
    var holeOutlineStrokeWidth = 1.4;

    // depth into the hole
    var bunnyOffset =
        _bunnyExitAnim.value * bunnyHeight + _bunnyDuckAnimation.value * 4.0;

    return
        // Top level container with the hole and clipped bunny image
        Container(
      height: bunnyHeight + holeOutlineStrokeWidth,
      width: clipOvalWidth,
      child: Stack(
        children: <Widget>[
          // hole
          Opacity(
            opacity: 1.0 - _holeTransformAnim.value,
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..scale(1.0 - _holeTransformAnim.value,
                          1.0 + _holeTransformAnim.value),
                    child: Image.asset('assets/images/layer35.png'))),
          ),
          // logo
          Opacity(
            opacity: _holeTransformAnim.value,
            child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..scale(1.0, _holeTransformAnim.value),
                    child: Image.asset('assets/images/logo_purple.png'))),
          ),

          // positioned oval clipped bunny
          Positioned(
              // clipping oval should sit on the top of the hole outline
              bottom: holeOutlineStrokeWidth,
              child: _buildOvalClippedBunny(
                bunnyHeight: bunnyHeight,
                bunnyWidth: bunnyWidth,
                clipOvalWidth: clipOvalWidth,
                bunnyOffset: bunnyOffset,
              )),
        ],
      ),
    );
  }

  // The ending (bottom) tile with the island and clipped bunny image
  Widget _buildEndTile() {
    var bunnyWidth = 30.0;
    var bunnyHeight = 48.0;
    var clipOvalWidth = 83.0;

    // depth into the hole
    var bunnyOffset = (1.0 - _bunnyEnterAnim.value) * bunnyHeight;
    var containerWidth = 375.0;

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Set the overall size of the layout, leaving space for the background
        Container(width: containerWidth, height: 200),

        // connected animation
        _buildBackgroundAnimation(),

        // island
        Image.asset('assets/images/island.png'),
        Opacity(
            opacity: _connectAnimController.value,
            child: Image.asset('assets/images/vignetteHomeHeroSm.png')),

        // positioned bunny
        Positioned(
            // clipping oval should sit on the top of the hole outline
            top: 70.0,
            left: containerWidth / 2 - clipOvalWidth / 2 + 5,
            child: _buildOvalClippedBunny(
              bunnyHeight: bunnyHeight,
              bunnyWidth: bunnyWidth,
              clipOvalWidth: clipOvalWidth,
              bunnyOffset: bunnyOffset,
            )),
      ],
    );
  }

  // Note: I tried a number of things here to position this relative to screen
  // Note: width but nothing was very satisfying. This animation really should
  // Note: probably be aligned with the island but stacked under the whole layout
  // Note: with a transparent gradient extending under the other screen items.
  // Note: Going with a fixed layout for now.
  Widget _buildBackgroundAnimation() {
    return Positioned(
      top: -38,
      child: Container(
        width: 375,
        height: 350,
        child: Opacity(
          opacity: _connectAnimController.value,
          child: FlareActor(
            'assets/flare/Connection_screens.flr',
            color: Colors.deepPurple.withOpacity(0.4),
            fit: BoxFit.fitHeight,
            animation: 'connectedLoop',
          ),
        ),
      ),
    );
  }

  // A transparent oval clipping container for the bunny with specified offset
  ClipOval _buildOvalClippedBunny(
      {double bunnyHeight,
      double bunnyWidth,
      double clipOvalWidth,
      double bunnyOffset}) {
    return ClipOval(
      child: Container(
          width: clipOvalWidth, // width of the hole
          height: bunnyHeight,
          //color: Colors.grey.withOpacity(0.3), // show clipping oval
          child: Stack(
            children: <Widget>[
              Positioned(
                  bottom: -bunnyOffset,
                  left: clipOvalWidth / 2 - bunnyWidth / 2 + 5,
                  child: Image.asset('assets/images/bunnypeek.png',
                      height: bunnyHeight)),
            ],
          )),
    );
  }

  Widget _buildNewHopTile() {
    return HopTile(
        title: s.newHop,
        image: Image.asset('assets/images/addCircleOutline.png'),
        trailing: SizedBox(width: 40),
        // match leading
        textColor: Colors.deepPurple,
        borderColor: Color(0xffb88dfc),
        dottedBorder: true,
        showDragHandle: false,
        onTap: _addHop);
  }

  Widget _buildDeletedHopsLink() {
    return Container(
      height: 45,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: LinkText(
          s.viewDeletedHops,
          style: AppText.linkStyle
              .copyWith(fontSize: 13, fontStyle: FontStyle.italic),
          onTapped: () {
            Navigator.pushNamed(context, '/settings/accounts');
          },
        ),
      ),
    );
  }

  Widget _buildStatusTile() {
    String text = s.orchidDisabled;
    Color color = Colors.redAccent.withOpacity(0.7);
    if (_connected()) {
      if (_hasHops()) {
        var num = _hops.length;
        text = s.numHopsConfigured(num);
        color = Colors.greenAccent.withOpacity(0.7);
      } else {
        text = s.trafficMonitoringOnly;
        color = Colors.yellowAccent.withOpacity(0.7);
      }
    }

    var status = OrchidAPI().connectionStatus.value;
    if (status == OrchidConnectionState.VPNConnecting) {
      text = s.starting;
      color = Colors.yellowAccent.withOpacity(0.7);
    }
    if (status == OrchidConnectionState.VPNConnected) {
      text = s.orchidConnecting;
      color = Colors.yellowAccent.withOpacity(0.7);
    }
    if (status == OrchidConnectionState.VPNDisconnecting) {
      text = s.orchidDisconnecting;
      color = Colors.yellowAccent.withOpacity(0.7);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.fiber_manual_record, color: color, size: 18),
          padx(5),
          Text(text,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Color(0xff504960),
              )),
        ],
      ),
    );
  }

  Dismissible _buildDismissableHopTile(UniqueHop uniqueHop) {
    return Dismissible(
      key: Key(uniqueHop.key.toString()),
      background: buildDismissableBackground(context),
      confirmDismiss: _confirmDeleteHop,
      onDismissed: (direction) {
        _deleteHop(uniqueHop);
      },
      child: _buildHopTile(uniqueHop),
    );
  }

  static Container buildDismissableBackground(BuildContext context) {
    return Container(
      color: Colors.red,
      child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              S.of(context).delete,
              style: TextStyle(color: Colors.white),
            ),
          )),
    );
  }

  Widget _buildHopTile(UniqueHop uniqueHop) {
    return buildHopTile(
      context: context,
      onTap: () {
        _viewHop(uniqueHop);
      },
      uniqueHop: uniqueHop,
      bgColor: _hopColorTween.value,
      showAlertBadge: _showHopAlert[uniqueHop.contentHash] ?? false,
    );
  }

  static Widget buildHopTile({
    @required BuildContext context,
    @required UniqueHop uniqueHop,
    VoidCallback onTap,
    Color bgColor,
    bool showAlertBadge,
  }) {
    //bool isFirstHop = uniqueHop.key == _hops.first.key;
    //bool hasMultipleHops = _hops.length > 1;
    //bool isLastHop = uniqueHop.key == _hops.last.key;
    Color color = Colors.white;
    Image image;
    String svgName;
    switch (uniqueHop.hop.protocol) {
      case HopProtocol.Orchid:
        image = Image.asset('assets/images/logo2.png', color: color);
        break;
      case HopProtocol.OpenVPN:
        svgName = 'assets/svg/openvpn.svg';
    break;
    case HopProtocol.WireGuard:
        svgName = 'assets/svg/wireguard.svg';
    break;
    }
    var title = uniqueHop.hop.displayName(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: HopTile(
        showAlertBadge: showAlertBadge,
        textColor: color,
        color: bgColor ?? Colors.white,
        image: image,
        svgName: svgName,
        onTap: onTap,
        key: Key(uniqueHop.key.toString()),
        title: title,
        showTopDivider: false,
      ),
    );
  }

  Container _buildEnableVPNInstruction() {
    return Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
        child: SafeArea(
          bottom: false,
          left: false,
          top: false,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(s.turnOnToActivate,
                    textAlign: TextAlign.right,
                    style: AppText.hopsInstructionsCallout),
              ),
              Padding(
                // attempt to align the arrow with switch in the header and text vertically
                padding: const EdgeInsets.only(left: 16, right: 6, bottom: 16),
                child: Image.asset('assets/images/drawnArrow3.png', height: 48),
              ),
            ],
          ),
        ));
  }

  Container _buildFirstHopInstruction() {
    return Container(
        // match hop tile horizontal padding
        padding: EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 0),
        child: SafeArea(
          left: true,
          bottom: false,
          right: false,
          top: false,
          child: Row(
            children: <Widget>[
              Padding(
                // align the arrow with the hop tile leading and text vertically
                padding: const EdgeInsets.only(left: 19, right: 0, bottom: 24),
                child: Image.asset('assets/images/drawnArrow2.png', height: 48),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(s.createFirstHop,
                      textAlign: TextAlign.left,
                      style: AppText.hopsInstructionsCallout),
                ),
              ),
            ],
          ),
        ));
  }

  ///
  /// Begin - Add / view hop logic
  ///

  void _addHop() async {
    CircuitUtils.addHop(context,
        onComplete: _addHopComplete, showCallouts: _hops.isEmpty);
  }

  // void _addHopFromPACPurchase() {
  //   CircuitUtils.purchasePAC(context, onComplete: _addHopComplete);
  // }

  // Local page state updates after hop addition.
  void _addHopComplete(UniqueHop uniqueHop) {
    // TODO: needed? Or does the global config change handle it?
    setState(() {
      _hops.add(uniqueHop);
    });

    // View the newly created hop:
    // Note: This performs a behavior like the iOS-Contacts App add flow,
    // Note: revealing the already pushed navigation state upon completing the
    // Note: add flow.  This non-animated push approximates this.
    if (CircuitPage.iOSContactsStyleAddHopBehavior) {
      _viewHop(uniqueHop, animated: false);
    }
  }

  void _saveCircuit() async {
    var circuit = Circuit(_hops.map((uniqueHop) => uniqueHop.hop).toList());
    CircuitUtils.saveCircuit(circuit);
    _showConfigurationChangedDialog();
  }

  void _showConfigurationChangedDialog() async {
    if (_dialogInProgress) {
      return;
    }
    try {
      _dialogInProgress = true;
      await ConfigChangeDialogs.showConfigurationChangeSuccess(context, warnOnly: true);
    } finally {
      _dialogInProgress = false;
    }
  }

  // View a hop selected from the circuit list
  void _viewHop(UniqueHop uniqueHop, {bool animated = true}) async {
    EditableHop editableHop = EditableHop(uniqueHop);
    HopEditor editor = editableHop.editor();
    await editor.show(context, animated: animated);

    // TODO: avoid saving if the hop was not edited.
    // Save the hop if it was edited.
    var index = _hops.indexOf(uniqueHop);
    setState(() {
      _hops.removeAt(index);
      _hops.insert(index, editableHop.value);
    });
    _saveCircuit();
  }

  // Callback for swipe to delete
  Future<bool> _confirmDeleteHop(dismissDirection) async {
    var result = await AppDialogs.showConfirmationDialog(
      context: context,
      title: s.confirmDelete,
      bodyText: s.deletingThisHopWillRemoveItsConfiguredOrPurchasedAccount +
          "  " +
          s.ifYouPlanToReuseTheAccountLaterYouShould,
    );
    return result;
  }

  // Callback for swipe to delete
  void _deleteHop(UniqueHop uniqueHop) async {
    var index = _hops.indexOf(uniqueHop);
    var removedHop = _hops.removeAt(index);
    setState(() {});
    _saveCircuit();
    // _recycleHopIfAllowed(uniqueHop);
    UserPreferences().addRecentlyDeletedHop(removedHop.hop);
  }

  // Recycle the hop if configured to do so.
  /*
  Future _recycleHopIfAllowed(UniqueHop uniqueHop) async {
    bool recycle = (await OrchidUserConfig.getUserConfigJS())
        .evalBoolDefault('pacs.recycle', false);
    if (recycle) {
      CircuitHop hop = uniqueHop.hop;
      if (hop is OrchidHop) {
        var keys = await UserPreferences().getKeys();
        EthereumAddress signer = hop.getSigner(keys);
        OrchidPACServerV0().recycle(funder: hop.funder, signer: signer);
      }
    }
  }*/

  // Callback for drag to reorder
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final UniqueHop hop = _hops.removeAt(oldIndex);
      _hops.insert(newIndex, hop);
    });
    _saveCircuit();
  }

  ///
  /// Begin - VPN Switch Logic
  ///

  // Note: By design the switch on this page does not track or respond to the
  // Note: connection state after initialization.  See `monitoring_page.dart`
  // Note: for a version of the switch that does attempt to track the connection.
  /*
  void _connectSwitchChanged(bool toEnabled) async {
    if (toEnabled) {
      bool allowNoHopVPN = await UserPreferences().allowNoHopVPN.get();
      if (_hasHops() || allowNoHopVPN) {
        _checkPermissionAndConnect();
      } else {
        _switchOn = false; // force the switch off
        _showWelcomeDialog();
      }
    } else {
      _disconnect();
    }
  }
   */

  // Note: By design the switch on this page does not track or respond to the
  // Note: connection state after initialization.  See `monitoring_page.dart`
  // Note: for a version of the switch that does attempt to track the connection.
  bool _connected() {
    var state = OrchidAPI().connectionStatus.value;
    switch (state) {
      case OrchidConnectionState.VPNDisconnecting:
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.VPNNotConnected:
      case OrchidConnectionState.VPNConnecting:
      case OrchidConnectionState.VPNConnected:
        return false;
      case OrchidConnectionState.OrchidConnected:
        return true;
      default:
        throw Exception();
    }
  }

  /// Called upon a change to Orchid connection state
  void _connectionStateChanged(OrchidConnectionState state,
      {bool animated = true}) {
    // We can't determine which animations may need to be run until hops are loaded.
    // Initialization will call us at least once after that.
    if (_hops == null) {
      return;
    }

    // Run animations based on which direction we are going.
    bool shouldShowConnected = _connected();
    bool showingConnected =
        _masterConnectAnimController.status == AnimationStatus.completed ||
            _masterConnectAnimController.status == AnimationStatus.forward;

    if (shouldShowConnected && !showingConnected && _hasHops()) {
      _masterConnectAnimController.forward(from: animated ? 0.0 : 1.0);
    }
    if (!shouldShowConnected && showingConnected) {
      _masterConnectAnimController.reverse(from: animated ? 1.0 : 0.0);
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Prompt for VPN permissions if needed and then start the VPN.
  // Note: If the UI will no longer be participating in the prompt then
  // Note: we can just do this routinely in the channel api on first launch.
  // Note: duplicates code in monitoring_page and legacy_connect_page.
  void _checkPermissionAndConnect() {
    UserPreferences().setDesiredVPNState(true);
    //if (_showEnableVPNInstruction()) {
    //UserPreferences().setVPNSwitchInstructionsViewed(true);
    //setState(() {
    //vpnSwitchInstructionsViewed = true;
    //});
    //}

    // Get the most recent status, blocking if needed.
    _rxSubs
        .add(OrchidAPI().vpnPermissionStatus.take(1).listen((installed) async {
      if (installed) {
        OrchidAPI().setConnected(true);
        setState(() {
          _switchOn = true;
        });
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
          setState(() {
            _switchOn = true;
          });
        } else {
          debugPrint('vpn: user skipped');
          setState(() {
            _switchOn = false;
          });
        }
      }
    }));
  }

  // Disconnect the VPN
  void _disconnect() {
    UserPreferences().setDesiredVPNState(false);
    OrchidAPI().setConnected(false);
    setState(() {
      _switchOn = false;
    });
  }

  ///
  /// Begin - util
  ///

  // Setter for the switch controller controlled state
  set _switchOn(bool on) {
    if (widget.switchController == null) {
      return;
    }
    widget.switchController.controlledState.value = on;
  }

  // Getter for the switch controller controlled state
//  bool get _switchOn {
//    return widget.switchController?.controlledState?.value ?? false;
//  }

  bool _hasHops() {
    return _hops != null && _hops.length > 0;
  }

  // TODO: No switch in current page impl so this is unused.
  /*
  void _showWelcomeDialog() async {
    var pacsEnabled = (await OrchidPurchaseAPI().apiConfig()).enabled;
    if (pacsEnabled) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return WelcomeDialog(
              onBuyCredits: _addHopFromPACPurchase,
              onSeeOptions: _addHop,
            );
          });
    } else {
      // TODO: Remove after PACs are in place on all platforms or when an alternate
      // TODO: fallback for the PACs feature flag exists.
      LegacyWelcomeDialog.show(
          context: context, onAddFlowComplete: _legacyWelcomeScreenAddHop);
    }
  }*/

  // TODO: Remove after PACs are in place on all platforms or when an alternate
  // TODO: fallback for the PACs feature flag exists.
  void _legacyWelcomeScreenAddHop(CircuitHop hop) async {
    var circuit = await UserPreferences().getCircuit() ?? Circuit([]);
    circuit.hops.add(hop);
    await UserPreferences().setCircuit(circuit);
    OrchidAPI().updateConfiguration();
    // Notify that the hops config has changed externally
    OrchidAPI().circuitConfigurationChanged.add(null);
  }

  void _userInteraction() {
    if (_bunnyDuckAnimation.value == 0) {
      _bunnyDuckAnimController.forward();
    }
    _lastInteractionTime = DateTime.now();
  }

  void _checkBunny(Timer timer) {
    var bunnyHideTime = Duration(seconds: 3);
    if (_bunnyDuckAnimation.value == 1.0 &&
        DateTime.now().difference(_lastInteractionTime) > bunnyHideTime) {
      _bunnyDuckAnimController.reverse();
    }
  }

  S get s {
    return S.of(context);
  }

  @override
  void dispose() {
    _rxSubs.forEach((sub) {
      sub.cancel();
    });
    _bunnyDuckTimer.cancel();
    //widget.switchController.onChange = null;
    _checkBalancesTimer.cancel();
    _masterConnectAnimController.dispose();
    _bunnyDuckAnimController.dispose();
    super.dispose();
  }
}

typedef HopCompletion = void Function(UniqueHop);

class CircuitUtils {
  // Show the add hop flow and save the result if completed successfully.
  static void addHop(BuildContext context,
      {HopCompletion onComplete, bool showCallouts = false}) async {
    // Create a nested navigation context for the flow. Performing a pop() from
    // this outer context at any point will properly remove the entire flow
    // (possibly multiple screens) with one appropriate animation.
    Navigator addFlow = Navigator(
      onGenerateRoute: (RouteSettings settings) {
        var addFlowCompletion = (CircuitHop result) {
          Navigator.pop(context, result);
        };
        var editor = AddHopPage(
            onAddFlowComplete: addFlowCompletion, showCallouts: showCallouts);
        var route = MaterialPageRoute<CircuitHop>(
            builder: (context) => editor, settings: settings);
        return route;
      },
    );
    var route = MaterialPageRoute<CircuitHop>(
        builder: (context) => addFlow, fullscreenDialog: true);
    _pushNewHopEditorRoute(context, route, onComplete);
  }

  // Push the specified hop editor to create a new hop, await the result, and
  // save it to the circuit.
  // Note: The paradigm here of the hop editors returning newly created or edited hops
  // Note: on the navigation stack decouples them but makes them more dependent on
  // Note: this update and save logic. We should consider centralizing this logic and
  // Note: relying on observation with `OrchidAPI.circuitConfigurationChanged` here.
  // Note: e.g.
  // Note: void _AddHopExternal(CircuitHop hop) async {
  // Note:   var circuit = await UserPreferences().getCircuit() ?? Circuit([]);
  // Note:   circuit.hops.add(hop);
  // Note:   await UserPreferences().setCircuit(circuit);
  // Note:   OrchidAPI().updateConfiguration();
  // Note:   OrchidAPI().circuitConfigurationChanged.add(null);
  // Note: }
  static void _pushNewHopEditorRoute(BuildContext context,
      MaterialPageRoute route, HopCompletion onComplete) async {
    var hop = await Navigator.push(context, route);
    if (hop == null) {
      return; // user cancelled
    }
    var uniqueHop =
        UniqueHop(hop: hop, key: DateTime.now().millisecondsSinceEpoch);
    addHopToCircuit(uniqueHop.hop);
    if (onComplete != null) {
      onComplete(uniqueHop);
    }
  }

  // Show the purchase PAC screen directly as a modal, skipping the 'add hop'
  // choice screen. This is used by the welcome dialog.
  /*
  static void purchasePAC(BuildContext context,
      {HopCompletion onComplete}) async {
    var addFlowCompletion = (CircuitHop result) {
      Navigator.pop(context, result);
    };
    var route = MaterialPageRoute<CircuitHop>(
        builder: (BuildContext context) {
          return PurchasePageV0(
            onAddFlowComplete: addFlowCompletion,
            cancellable: true,
          );
        },
        fullscreenDialog: true);
    _pushNewHopEditorRoute(context, route, onComplete);
  }*/

  static void addHopToCircuit(CircuitHop hop) async {
    var circuit = await UserPreferences().getCircuit();
    circuit.hops.add(hop);
    saveCircuit(circuit);
  }

  static void saveCircuit(Circuit circuit) async {
    UserPreferences().setCircuit(circuit);
    OrchidAPI().updateConfiguration();
    OrchidAPI().circuitConfigurationChanged.add(null);
  }
}
