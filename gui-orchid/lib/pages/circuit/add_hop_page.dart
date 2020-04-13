import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:orchid/api/purchase/orchid_purchase.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/onboarding/welcome_dialog.dart';
import 'package:orchid/pages/purchase/purchase_page.dart';
import 'hop_editor.dart';
import 'model/circuit_hop.dart';
import 'openvpn_hop_page.dart';
import 'orchid_hop_page.dart';

typedef AddFlowCompletion = void Function(CircuitHop result);

class AddHopPage extends StatefulWidget {
  final AddFlowCompletion onAddFlowComplete;
  final bool showCallouts;

  const AddHopPage({Key key, this.onAddFlowComplete, this.showCallouts})
      : super(key: key);

  @override
  _AddHopPageState createState() => _AddHopPageState();
}

class _AddHopPageState extends State<AddHopPage> {
  bool _showPACs = false;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    _showPACs = await OrchidPurchaseAPI.pacsEnabled();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: s.addHop,
      cancellable: true,
      backAction: () {
        widget.onAddFlowComplete(null);
      },
      decoration: BoxDecoration(),
      // no gradient
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                pady(40),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Image.asset("assets/images/approach.png", height: 100),
                ),
                pady(24),
                Text(s.selectYourHop,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 22.0 / 17.0,
                        letterSpacing: 0.16,
                        color: Color(0xff504960))),
                pady(24),

                // QR Code
                _divider(),
                _buildHopChoice(
                    text: s.iHaveAQRCode,
                    onTap: () {
                      WelcomeDialog.show(
                          context: context,
                          onAddFlowComplete: widget.onAddFlowComplete);
                    },
                    imageName: "assets/images/scan.png"),

                // PAC Purchase
                if (_showPACs)
                  _divider(),
                if (_showPACs)
                  _buildHopChoice(
                      text: s.purchasePAC,
                      onTap: () {
                        _addHopFromPACPurchase();
                      },
                      imageName: "assets/images/logo_small_purple.png"),

                // Try Orchid
                _divider(),
                _buildHopChoice(
                    //text: s.iWantToTryOrchid,
                    text: s.iHaveOrchidAccount,
                    onTap: () {
                      _addHopType(HopProtocol.Orchid);
                    },
                    imageName: "assets/images/logo_small_purple.png"),

                // VPN Subscription
                _divider(),
                _buildHopChoice(
                    text: s.iHaveAVPNSubscription,
                    onTap: () {
                      _addHopType(HopProtocol.OpenVPN);
                    },
                    imageName: "assets/images/security_purple.png"),

                _divider(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHopChoice(
      {String text, imageName: String, VoidCallback onTap, Widget trailing}) {
    return ListTile(
        contentPadding: EdgeInsets.only(left: 0, right: 8, top: 8, bottom: 8),
        leading: Image.asset(imageName, width: 24, height: 24),
        trailing:
            trailing ?? Icon(Icons.chevron_right, color: Colors.deepPurple),
        title: Text(text,
            textAlign: TextAlign.left,
            style: const TextStyle(
                color: const Color(0xff3a3149),
                fontWeight: FontWeight.w400,
                fontFamily: "SFProText",
                fontStyle: FontStyle.normal,
                fontSize: 18.0)),
        onTap: onTap);
  }

  // Push a hop editor and then await the CircuitHop result.
  void _addHopType(HopProtocol hopType) async {
    EditableHop editableHop = EditableHop.empty();
    HopEditor editor;
    switch (hopType) {
      case HopProtocol.Orchid:
        editor = OrchidHopPage(
          editableHop: editableHop,
          mode: HopEditorMode.Create,
          onAddFlowComplete: widget.onAddFlowComplete,
        );
        break;
      case HopProtocol.OpenVPN:
        editor = OpenVPNHopPage(
          editableHop: editableHop,
          mode: HopEditorMode.Create,
          onAddFlowComplete: widget.onAddFlowComplete,
        );
        break;
    }
    var route = MaterialPageRoute<CircuitHop>(builder: (context) => editor);
    _pushCircuitBuilderRoute(route);
  }

  // Perform a PAC purchase and await the resulting hop result.
  // Return the resulting hop on the navigation stack as we pop this view.
  void _addHopFromPACPurchase() async {
    var route = MaterialPageRoute<CircuitHop>(builder: (BuildContext context) {
      return PurchasePage(onAddFlowComplete: widget.onAddFlowComplete);
    });
    _pushCircuitBuilderRoute(route);
  }

  // Push the editor or other builder that returns a circuit hop.
  void _pushCircuitBuilderRoute(MaterialPageRoute<CircuitHop> route) async {
    // If the editor invokes the addFlowComplete, which should be the case on a save,
    // this entire flow will be popped to the caller and control will not return here.
    CircuitHop hop = await Navigator.push(context, route);
    // If hop is null the user backed out of the editor: Fall through and allow another choice.
    if (hop != null) {
      // Handle a return here for completeness.
      Navigator.pop(context, hop);
    }
  }

  Divider _divider() =>
      Divider(color: Colors.black.withOpacity(0.3), height: 1.0);

  S get s {
    return S.of(context);
  }
}
