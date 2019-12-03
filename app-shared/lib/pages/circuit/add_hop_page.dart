import 'package:flutter/material.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_colors.dart';
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
      title: "Select Hop Type",
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
            Expanded(child: AddHopInstructions()),
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

class AddHopInstructions extends StatelessWidget {
  final VoidCallback addHop;

  const AddHopInstructions({Key key, this.addHop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        return Visibility(
          visible: orientation == Orientation.portrait,
          child: SafeArea(
          child: Column(
            children: <Widget>[
              Spacer(flex: 1),
              Image.asset("assets/images/approach.png"),
              SizedBox(height: 20),
              AppText.header(
                  text: "Choose your protocol",
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 20.0),
              SizedBox(height: 20),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45),
                  child: AppText.body(
                      text:
                          "There are two types of hops to choose from. You can route your traffic through one of Orchid’s secure servers or you can use your existing VPN provider’s OpenVPN configuration.",
                      fontSize: 15.0,
                      color: AppColors.neutral_1),
                ),
              ),
              Spacer(flex: 1),
            ],
          )),
        );
      },
    );
  }
}
