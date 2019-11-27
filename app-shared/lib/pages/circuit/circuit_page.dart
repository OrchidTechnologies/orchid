import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/circuit/openvpn_hop_page.dart';
import 'package:orchid/pages/circuit/orchid_hop_page.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/keys/keys_page.dart';
import 'package:orchid/util/collections.dart';

import '../app_gradients.dart';
import '../app_text.dart';
import 'add_hop_page.dart';
import 'circuit_hop.dart';

class CircuitPage extends StatefulWidget {
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
        }))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.basicGradient),
      child: SafeArea(
        child: Column(
          children: <Widget>[
            pady(16),
            Expanded(child: _buildListView()),
            FloatingAddButton(onPressed: _addHop),
          ],
        ),
      ),
    );
  }

  ReorderableListView _buildListView() {
    return ReorderableListView(
        children: (_hops ?? []).map((uniqueHop) {
          return Dismissible(
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
            child: ListTile(
              onTap: () {
                _viewHop(uniqueHop);
              },
              key: Key(uniqueHop.key.toString()),
              title: Text(
                uniqueHop.hop.displayName(),
                style: AppText.listItem,
              ),
              trailing: Icon(Icons.menu),
            ),
            key: Key(uniqueHop.key.toString()),
          );
        }).toList(),
        onReorder: _onReorder);
  }

  void _addHop() async {
    var editor = AddHopPage();
    var route = MaterialPageRoute<CircuitHop>(
        builder: (context) => editor, fullscreenDialog: true);
    var hop = await Navigator.push(context, route);
    if (hop == null) {
      return; // user cancelled
    }
    var uniqueHop =
        UniqueHop(hop: hop, key: DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _hops.add(uniqueHop);
    });
    _saveCircuit();
  }

  void _viewHop(UniqueHop uniqueHop) async {
    EditableHop editableHop = EditableHop(uniqueHop);
    var editor;
    switch (uniqueHop.hop.protocol) {
      case Protocol.Orchid:
        editor = OrchidHopPage(editableHop: editableHop);
        break;
      case Protocol.OpenVPN:
        editor = OpenVPNHopPage(editableHop: editableHop);
        break;
    }
    _showEditor(editor);
  }

  /*
  void _editHop(UniqueHop uniqueHop) async {
    EditableHop editableHop = EditableHop(uniqueHop);
    var editor;
    switch (uniqueHop.hop.protocol) {
      case Protocol.Orchid:
        editor = OrchidHopPage(editableHop: editableHop);
        break;
      case Protocol.OpenVPN:
        editor = OpenVPNHopPage(editableHop: editableHop);
        break;
    }

    await _showEditor(editor);
    var index = _hops.indexOf(uniqueHop);
    setState(() {
      _hops.removeAt(index);
      _hops.insert(index, editableHop.value);
    });
    _saveCircuit();
  }
   */

  Future<void> _showEditor(editor) async {
    var route = MaterialPageRoute(builder: (context) => editor);
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

  void _saveCircuit() {
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
}
