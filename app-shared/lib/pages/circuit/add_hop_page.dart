import 'package:flutter/material.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'circuit_hop.dart';
import 'openvpn_hop_page.dart';
import 'orchid_hop_page.dart';

class AddHopPage extends StatefulWidget {
  @override
  _AddHopPageState createState() => _AddHopPageState();
}

class _AddHopPageState extends State<AddHopPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: "Add Circuit Hop",
      child: SafeArea(
        child: Column(
          children: <Widget>[
            pady(8),
            _buildChoice(
                text: "Orchid Hop",
                onPressed: () {
                  _addHopType(Protocol.Orchid);
                }),
            _divider(),
            _buildChoice(
                text: "OpenVPN Hop",
                onPressed: () {
                  _addHopType(Protocol.OpenVPN);
                }),
            _divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildChoice({String text, VoidCallback onPressed}) {
    return ListTile(
        contentPadding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
        trailing: Icon(Icons.chevron_right, color: Colors.black),
        title:
            Text(text, textAlign: TextAlign.left, style: AppText.dialogTitle),
        onTap: onPressed);
  }

  void _addHopType(Protocol hopType) async {
    EditableHop editableHop = EditableHop.empty();
    HopEditor editor;
    switch (hopType) {
      case Protocol.Orchid:
        editor = OrchidHopPage(
          editableHop: editableHop,
          showSave: true,
        );
        break;
      case Protocol.OpenVPN:
        editor = OpenVPNHopPage(
          editableHop: editableHop,
          showSave: true,
        );
        break;
    }
    var route = MaterialPageRoute<CircuitHop>(builder: (context) => editor);
    var hop = await Navigator.push(context, route);
    // If we have a hop the user saved, else allow another choice.
    if (hop != null) {
      Navigator.pop(context, hop);
    }
  }

  Divider _divider() =>
      Divider(color: Colors.black.withOpacity(0.3), height: 1.0);
}
