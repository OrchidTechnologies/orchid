import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/circuit/circuit_add_page.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/util/collections.dart';

import '../app_colors.dart';
import '../app_text.dart';
import 'hop.dart';

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
    setState(() {
      // Wrap the hops with a locally unique id for the UI
      _hops = mapIndexed(
              circuit?.hops ?? [],
              ((index, hop) => UniqueHop(
                  key: DateTime.now().millisecondsSinceEpoch + index,
                  hop: hop)))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.grey_7, AppColors.grey_6])),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Circuit",
                style: AppText.headerStyle.copyWith(color: Colors.black),
              ),
            ),
            Expanded(child: _buildListView()),
            FloatingActionButton(
              child: Icon(Icons.add),
              onPressed: _addHop,
            ),
            pady(36.0),
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
                _editHop(uniqueHop);
              },
              key: Key(uniqueHop.key.toString()),
              title: Text(
                "Orchid",
                style: AppText.dialogTitle,
              ),
              trailing: Icon(Icons.menu),
            ),
            key: Key(uniqueHop.key.toString()),
          );
        }).toList(),
        onReorder: _onReorder);
  }

  void _addHop() async {
    var route =
        MaterialPageRoute<UniqueHop>(builder: (context) => CircuitAddPage());
    UniqueHop result = await Navigator.push(context, route);
    if (_hops == null) {
      _hops = [];
    }
    setState(() {
      _hops.add(result);
    });
    _saveCircuit();
  }

  void _editHop(UniqueHop uniqueHop) async {
    var route = MaterialPageRoute<UniqueHop>(
        builder: (context) => CircuitAddPage(
            initialFunder: uniqueHop.hop.funder,
            initialSecret: uniqueHop.hop.secret));
    UniqueHop updated = await Navigator.push(context, route);
    var index = _hops.indexOf(uniqueHop);
    setState(() {
      _hops.removeAt(index);
      _hops.insert(index, updated);
    });
    _saveCircuit();
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
