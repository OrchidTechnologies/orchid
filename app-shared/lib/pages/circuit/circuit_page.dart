import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/circuit/openvpn_hop_page.dart';
import 'package:orchid/pages/circuit/orchid_hop_page.dart';
import 'package:orchid/pages/common/app_reorderable_list.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/keys/keys_page.dart';
import 'package:orchid/util/collections.dart';

import '../app_colors.dart';
import '../app_gradients.dart';
import '../app_text.dart';
import '../app_transitions.dart';
import 'add_hop_page.dart';
import 'hop_editor.dart';
import 'hop_tile.dart';
import 'model/circuit.dart';
import 'model/circuit_hop.dart';

class CircuitPage extends StatefulWidget {
  CircuitPage({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new CircuitPageState();
  }
}

class CircuitPageState extends State<CircuitPage> {
  List<StreamSubscription> _rxSubs = List();
  List<UniqueHop> _hops;
  bool _switchOn;

  // Workaround for dragged switch state issue
  // https://github.com/flutter/flutter/issues/46046
  int _switchKey = 0;

  @override
  void initState() {
    super.initState();
    _switchOn = _initialSwitchState();
    initStateAsync();
  }

  void initStateAsync() async {
    var circuit = await UserPreferences().getCircuit();
    if (mounted) {
      setState(() {
        // Wrap the hops with a locally unique id for the UI
        _hops = mapIndexed(circuit?.hops ?? [], ((index, hop) {
          var key = DateTime.now().millisecondsSinceEpoch + index;
          return UniqueHop(key: key, hop: hop);
        })).toList();
      });
    }

    // Update the UI on connection status changes
    _rxSubs.add(OrchidAPI().connectionStatus.listen((state) {
      print("connection state changed: $state");
      setState(() {});
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.basicGradient),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Visibility(
      visible: _hops != null,
      replacement: Container(),
      child: Stack(
        children: <Widget>[
          _buildHopList(),
          if (_hasHops())
            _buildFloatingActionButton()
          else
            _buildBottomButtonCallout()
        ],
      ),
    );
  }

  Align _buildFloatingActionButton() {
    return Align(
        alignment: Alignment.bottomRight,
        child: FloatingAddButton(onPressed: _addHop));
  }

  Widget _buildBottomButtonCallout() {
    return OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Visibility(
            visible: orientation == Orientation.portrait,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45.0),
              child: AppText.header(
                  text: "Create your first hop for IP protection.",
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Image.asset("assets/images/drawnArrow.png"),
                FloatingAddButton(
                    padding:
                        EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 0),
                    onPressed: _addHop),
              ],
            ),
          ),
        ],
      );
    });
  }

  // Warn when no vpn protection is actually in effect.
  bool _showProtectedWarning() {
    // Note: The native side reports connected whenever the VPN is running,
    // Note: including for traffic monitoring only.
    return !_hasHops() || !_connected();
  }

  bool _showEnableVPNInstruction() {
    return _hasHops() && !_connected();
  }

  Widget _buildHopList() {
    return Column(
      children: <Widget>[
        pady(24),
        Expanded(
          child: AppReorderableListView(
              header: Column(
                children: <Widget>[
                  _buildStartTile(),
                  if (_showEnableVPNInstruction()) _buildEnableVPNInstruction(),
                  _buildFirewallTile()
                ],
              ),
              children: (_hops ?? []).map((uniqueHop) {
                return _buildDismissableHopTile(uniqueHop);
              }).toList(),
              footer: Column(
                children: <Widget>[
                  _buildEndTile(),
                  if (_showProtectedWarning()) _buildWarningTile(),
                ],
              ),
              onReorder: _onReorder),
        ),
      ],
    );
  }

  // The starting (top) tile in the hop flow
  Widget _buildStartTile() {
    return HopTile(
        title: "Your Device",
        image: Image.asset("assets/images/person.png"),
        gradient: AppGradients.purpleTileHorizontal,
        textColor: Colors.white,
        trailing: _buildSwitch(),
        showDragHandle: false,
        // Show the bottom flow arrow unless we are showing the enable instructions
        showFlowDividerBottom: !_showEnableVPNInstruction());
  }

  // The ending (bottom) tile in the hop flow
  Widget _buildEndTile() {
    return HopTile(
        title: "The Internet",
        image: Image.asset("assets/images/globe.png"),
        gradient: AppGradients.purpleTileHorizontal,
        textColor: Colors.white,
        showDragHandle: false,
        showFlowDividerTop: _hops != null && _hops.length > 0);
  }

  Widget _buildWarningTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text("️⚠️️ Your IP is exposed!",
          style:
              AppText.listItem.copyWith(fontSize: 18, color: Colors.redAccent)),
    );
  }

  Widget _buildFirewallTile() {
    var color = Colors.white;
    return HopTile(
        title: "Personal Firewall",
        image: Image.asset("assets/images/fire.png", color: color),
        gradient: AppGradients.purpleTileHorizontal,
        textColor: color,
        showDragHandle: false,
        showFlowDividerBottom: true);
  }

  Dismissible _buildDismissableHopTile(UniqueHop uniqueHop) {
    return Dismissible(
      key: Key(uniqueHop.key.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            )),
      ),
      onDismissed: (direction) {
        _deleteHop(uniqueHop);
      },
      child: _buildHopTile(uniqueHop),
    );
  }

  Widget _buildHopTile(UniqueHop uniqueHop) {
    bool isFirstHop = uniqueHop.key == _hops.first.key;
    bool hasMultipleHops = _hops.length > 1;
    Color color = Colors.teal;
    Image image;
    switch (uniqueHop.hop.protocol) {
      case Protocol.Orchid:
        image = Image.asset("assets/images/logo2.png", color: color);
        break;
      case Protocol.OpenVPN:
        image = Image.asset("assets/images/security.png", color: color);
        break;
      default:
        throw new Exception();
    }
    return HopTile(
        textColor: color,
        image: image,
        onTap: () {
          _viewHop(uniqueHop);
        },
        key: Key(uniqueHop.key.toString()),
        title: uniqueHop.hop.displayName(),
        showTopDivider: isFirstHop,
        showDragHandle: hasMultipleHops);
  }

  Container _buildEnableVPNInstruction() {
    // Providing the instructions a fixed height allows this to work.
    // TODO: Why doesn't IntrinsicHeight work here?
    return Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
        child: SafeArea(
          child: Row(
            children: <Widget>[
              Expanded(
                child: AppText.header(
                    text:
                        "Turn Orchid on to activate your hops and protect your traffic",
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: RotatedBox(
                    child:
                        Image.asset("assets/images/drawnArrow.png", height: 34),
                    quarterTurns: 3),
              ),
            ],
          ),
        ));
  }

  ///
  /// Begin - Add / view hop logic
  ///

  // Show the add hop flow and save the result if completed successfully.
  void _addHop() async {
    // Create a nested navigation context for the flow.
    // Performing a pop() from this outer context at any point will properly
    // remove the entire flow with the correct animation.
    var addFlow = Navigator(
      onGenerateRoute: (RouteSettings settings) {
        print("generate route: $settings");
        var addFlowCompletion = (CircuitHop result) {
          Navigator.pop(context, result);
        };
        var editor = AddHopPage(onAddFlowComplete: addFlowCompletion);
        var route = MaterialPageRoute<CircuitHop>(
            builder: (context) => editor, settings: settings);
        return route;
      },
    );
    var route = MaterialPageRoute<CircuitHop>(
        builder: (context) => addFlow, fullscreenDialog: true);

    var hop = await Navigator.push(context, route);
    print("hop = $hop");

    if (hop == null) {
      return; // user cancelled
    }
    var uniqueHop =
        UniqueHop(hop: hop, key: DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _hops.add(uniqueHop);
    });
    _saveCircuit();

    // View the newly created hop:
    // Note: ideally we would like this to act like the iOS Contacts add flow,
    // Note: revealing the already pushed navigation state upon completing the
    // Note: add flow.  Doing a non-animated push approximates this.
    _viewHop(uniqueHop, animated: false);
  }

  // View a hop selected from the circuit list
  void _viewHop(UniqueHop uniqueHop, {bool animated = true}) async {
    EditableHop editableHop = EditableHop(uniqueHop);
    var editor;
    switch (uniqueHop.hop.protocol) {
      case Protocol.Orchid:
        editor =
            OrchidHopPage(editableHop: editableHop, mode: HopEditorMode.View);
        break;
      case Protocol.OpenVPN:
        editor = OpenVPNHopPage(
          editableHop: editableHop,
          mode: HopEditorMode.Edit,
        );
        break;
    }
    await _showEditor(editor, animated: animated);

    // TODO: avoid saving if the hop was not edited.
    // Save the hop if it was edited.
    var index = _hops.indexOf(uniqueHop);
    setState(() {
      _hops.removeAt(index);
      _hops.insert(index, editableHop.value);
    });
    _saveCircuit();
  }

  Future<void> _showEditor(editor, {bool animated = true}) async {
    var route = animated
        ? MaterialPageRoute(builder: (context) => editor)
        : NoAnimationMaterialPageRoute(builder: (context) => editor);
    await Navigator.push(context, route);
  }

  // Callback for swipe to delete
  void _deleteHop(UniqueHop uniqueHop) {
    var index = _hops.indexOf(uniqueHop);
    setState(() {
      _hops.removeAt(index);
    });
    _saveCircuit();
  }

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

  Switch _buildSwitch() {
    return Switch(
      key: Key(_switchKey.toString()),
        activeColor: AppColors.purple_5,
        value: _switchOn ?? false,
        onChanged: (bool newValue) {
          _setConnectionState(newValue);
        });
  }

  // Get the initial state of the vpn switch based on the connection state.
  // Note: By design the switch on this page does not track or respond to the
  // Note: connection state after initialization.  See `monitoring_page.dart`
  // Note: for a version of the switch that does attempt to track the connection.
  bool _initialSwitchState() {
    var connectionState =
        OrchidAPI().connectionStatus.value ?? OrchidConnectionState.Invalid;
    switch (connectionState) {
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.NotConnected:
        return false; // off
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.Connected:
      case OrchidConnectionState.Disconnecting:
        return true; // on
      default:
        throw Exception();
    }
  }

  // Note: By design the switch on this page does not track or respond to the
  // Note: connection state after initialization.  See `monitoring_page.dart`
  // Note: for a version of the switch that does attempt to track the connection.
  void _setConnectionState(bool desiredEnabled) {
    _switchKey++;
    if(desiredEnabled) {
      _checkPermissionAndEnableConnection();
    } else {
      OrchidAPI().setConnected(false);
      setState(() {
        _switchOn = false;
      });
    }
  }

  // Prompt for VPN permissions if needed and then start the VPN.
  // Note: If the UI will no longer be participating in the prompt then
  // Note: we can just do this routinely in the channel api on first launch.
  // Note: duplicates code in monitoring_page and connect_page.
  void _checkPermissionAndEnableConnection() {
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
          debugPrint("vpn: user chose to install");
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
          debugPrint("vpn: user skipped");
          setState(() {
            _switchOn = false;
          });
        }
      }
    }));
  }

  ///
  /// Begin - util
  ///

  bool _hasHops() {
    return _hops != null && _hops.length > 0;
  }

  // Note: By design the switch on this page does not track or respond to the
  // Note: connection state after initialization.  See `monitoring_page.dart`
  // Note: for a version of the switch that does attempt to track the connection.
  bool _connected() {
    //return OrchidAPI().connectionStatus.value == OrchidConnectionState.Connected;
    return _switchOn;
  }

  void _saveCircuit() async {
    var circuit = Circuit(_hops.map((uniqueHop) => uniqueHop.hop).toList());
    UserPreferences().setCircuit(circuit);
    OrchidAPI().updateConfiguration();
  }

  @override
  void dispose() {
    super.dispose();
    _rxSubs.forEach((sub) {
      sub.cancel();
    });
  }
}
