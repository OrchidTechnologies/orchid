import 'package:flutter/material.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'circuit_hop.dart';
import 'openvpn_hop_page.dart';
import 'orchid_hop_page.dart';

typedef AddFlowCompletion = void Function(CircuitHop result);

class AddHopPage extends StatefulWidget {
  final AddFlowCompletion onAddFlowComplete;

  const AddHopPage({Key key, this.onAddFlowComplete}) : super(key: key);

  @override
  _AddHopPageState createState() => _AddHopPageState();
}

class _AddHopPageState extends State<AddHopPage> {
  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: "Add Circuit Hop",
      cancellable: true,
      backAction: () {
        widget.onAddFlowComplete(null);
      },
      child: SafeArea(
        child: Column(
          children: <Widget>[
            pady(8),
            _buildHopChoice(text: "Orchid Hop", hopType: Protocol.Orchid),
            _divider(),
            _buildHopChoice(text: "OpenVPN Hop", hopType: Protocol.OpenVPN),
            _divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildHopChoice({String text, Protocol hopType}) {
    return ListTile(
        contentPadding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
        trailing: Icon(Icons.chevron_right, color: Colors.black),
        title:
            Text(text, textAlign: TextAlign.left, style: AppText.dialogTitle),
        onTap: () {
          _addHopType(hopType);
        });
  }

  void _addHopType(Protocol hopType) async {
    EditableHop editableHop = EditableHop.empty();
    HopEditor editor;
    switch (hopType) {
      case Protocol.Orchid:
        editor = OrchidHopPage(
          editableHop: editableHop,
          mode: HopEditorMode.Create,
          onAddFlowComplete: widget.onAddFlowComplete,
        );
        break;
      case Protocol.OpenVPN:
        editor = OpenVPNHopPage(
          editableHop: editableHop,
          mode: HopEditorMode.Create,
          onAddFlowComplete: widget.onAddFlowComplete,
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
