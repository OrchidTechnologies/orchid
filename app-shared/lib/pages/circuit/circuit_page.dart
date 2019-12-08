import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/circuit/openvpn_hop_page.dart';
import 'package:orchid/pages/circuit/orchid_hop_page.dart';
import 'package:orchid/pages/common/app_reorderable_list.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/instructions_view.dart';
import 'package:orchid/pages/keys/keys_page.dart';
import 'package:orchid/util/collections.dart';

import '../app_gradients.dart';
import '../app_text.dart';
import 'add_hop_page.dart';
import 'circuit_empty_view.dart';
import 'hop_editor.dart';
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
  List<UniqueHop> _hops;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.basicGradient),
      child: Stack(
        children: <Widget>[
          Visibility(
              visible: _showEmptyView(),
              child: CircuitEmptyView(addHop: _addHop),
              replacement: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: <Widget>[
        Visibility(visible: _hops != null, child: _buildHopList()),
        Align(
            alignment: Alignment.bottomRight,
            child: FloatingAddButton(onPressed: _addHop)),
      ],
    );
  }

  // Empty state instructions
  bool _showEmptyView() {
    return _hops != null && _hops.length == 0;
  }

  // (Success!) Instructions shown when the user has a single hop configured
  bool _showSingleHopInstructions() {
    return _hops != null && _hops.length == 1;
  }

  Widget _buildHopList() {
    return Column(
      children: <Widget>[
        pady(24),
        //_divider(),
        Expanded(
          child: AppReorderableListView(
              header: Column(
                children: <Widget>[_buildStartTile(), _buildFirewallTile()],
              ),
              children: (_hops ?? []).map((uniqueHop) {
                return _buildHopListItem(uniqueHop);
              }).toList(),
              footer: Column(
                children: <Widget>[
                  _buildEndTile(),
                  Visibility(
                      visible: _showSingleHopInstructions(),
                      // Providing the instructions a fixed height allows this to work.
                      // TODO: Why doesn't IntrinsicHeight work here?
                      child: Container(
                        padding: EdgeInsets.only(top: 50),
                        height: 300,
                        child: InstructionsView(
                          image: Image.asset("assets/images/hi5.png"),
                          title: "Success!",
                          body:
                              "You now have a configured single-hop route for your internet traffic. Each hop you add brings a layer of indirection and obfuscation to your connection - as long as each is independently funded from a new source.",
                        ),
                      ))
                ],
              ),
              onReorder: _onReorder),
        ),
      ],
    );
  }

  Widget _buildStartTile() {
    return _buildTileWithDivider(
      title: "Your Device",
      image: Image.asset("assets/images/person.png"),
      gradient: AppGradients.purpleTileHorizontal,
      textColor: Colors.white,
      showDragHandle: false,
    );
  }

  Widget _buildEndTile() {
    return _buildTileWithDivider(
      title: "The Internet",
      image: Image.asset("assets/images/globe.png"),
      gradient: AppGradients.purpleTileHorizontal,
      textColor: Colors.white,
      showDragHandle: false,
    );
  }

  Widget _buildFirewallTile() {
    var color = Colors.deepPurple;
    return _buildTileWithDivider(
      title: "Personal Firewall",
      image: Image.asset("assets/images/fire.png", color: color),
      textColor: color,
      showDragHandle: false,
    );
  }

  Dismissible _buildHopListItem(UniqueHop uniqueHop) {
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
      child: _buildHopTileWithDivider(uniqueHop),
    );
  }

  Widget _buildHopTileWithDivider(UniqueHop uniqueHop) {
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
    return _buildTileWithDivider(
      textColor: color,
      image: image,
      onTap: () {
        _viewHop(uniqueHop);
      },
      key: Key(uniqueHop.key.toString()),
      title: uniqueHop.hop.displayName(),
    );
  }

  Widget _buildTileWithDivider({
    String title,
    VoidCallback onTap,
    Key key,
    Image image,
    Color textColor,
    Color color,
    Gradient gradient,
    bool showDragHandle = true,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(0),
          decoration: BoxDecoration(color: color, gradient: gradient),
          // Allow the tile background to extend into the safe area but not the content
          child: SafeArea(
            child: ListTile(
                onTap: onTap,
                key: key,
                title: Text(
                  title,
                  style: AppText.listItem.copyWith(color: textColor),
                ),
                leading: image,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (showDragHandle) Icon(Icons.menu),
                    if (onTap != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(Icons.chevron_right),
                      ),
                  ],
                )),
          ),
        ),
        _divider()
      ],
    );
  }

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

  void _saveCircuit() async {
    var circuit = Circuit(_hops.map((uniqueHop) => uniqueHop.hop).toList());
    UserPreferences().setCircuit(circuit);
    OrchidAPI().updateConfiguration();
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

  Widget _divider() {
    return Container(height: 1.0, color: Color(0xffd5d7e2));
  }
}

// https://stackoverflow.com/a/53503738/74975
class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    @required WidgetBuilder builder,
    RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
            builder: builder,
            maintainState: maintainState,
            settings: settings,
            fullscreenDialog: fullscreenDialog);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    /*
    // Experimenting with making this one-way.
    if (animation.status == AnimationStatus.reverse) {
      var begin = Offset.zero;
      var end = Offset(0.0, 1.0);
      var tween = Tween(begin: begin, end: end);
      var offsetAnimation = animation.drive(tween);
      return SlideTransition(
          position: offsetAnimation,
          child: child
      );
    } else {
      return child;
    }
     */
    return child;
  }
}
