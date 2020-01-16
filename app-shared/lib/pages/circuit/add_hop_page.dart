import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_vpn_config.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'hop_editor.dart';
import 'model/circuit_hop.dart';
import 'openvpn_hop_page.dart';
import 'orchid_hop_page.dart';
import 'package:flutter/services.dart';

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
  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: "New Hop",
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
                Text("Choose your Hop type",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 22.0 / 17.0,
                        letterSpacing: 0.16,
                        color: Color(0xff504960))),
                pady(24),
                if (widget.showCallouts) _buildOrchidInstruction(),
                _divider(),
                _buildHopChoice(
                    text: "Scan QR Code",
                    onTap: () { _importQRCode(context); },
                    imageName: "assets/images/scan.png",
                    trailing: SizedBox(width: 1)),
                _divider(),
                _buildHopChoice(
                    text: "Orchid Hop",
                    onTap: () {
                      _addHopType(HopProtocol.Orchid);
                    },
                    imageName: "assets/images/logo_small_purple.png"),
                _divider(),
                _buildHopChoice(
                    text: "OpenVPN Hop",
                    onTap: () {
                      _addHopType(HopProtocol.OpenVPN);
                    },
                    imageName: "assets/images/security_purple.png"),
                _divider(),
                if (widget.showCallouts) _buildVPNInstruction(),
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
    var hop = await Navigator.push(context, route);
    // If we have a hop the user saved, else allow another choice.
    if (hop != null) {
      Navigator.pop(context, hop);
    }
  }

  Container _buildOrchidInstruction() {
    return Container(
        // match hop tile horizontal padding
        child: SafeArea(
      left: true,
      bottom: false,
      right: false,
      top: false,
      child: Row(
        children: <Widget>[
          Padding(
            // align the arrow with the hop tile leading and text vertically
            padding:
                const EdgeInsets.only(left: 11, right: 0, top: 0, bottom: 12),
            child: RotatedBox(
              child: Image.asset("assets/images/drawnArrow3.png", height: 32),
              quarterTurns: 2,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 21),
              child: Text("I want to try Orchid",
                  textAlign: TextAlign.left,
                  style: AppText.hopsInstructionsCallout),
            ),
          ),
        ],
      ),
    ));
  }

  Container _buildVPNInstruction() {
    return Container(
        // match hop tile horizontal padding
        child: SafeArea(
      left: true,
      bottom: false,
      right: false,
      top: false,
      child: Row(
        children: <Widget>[
          Padding(
            // align the arrow with the hop tile leading and text vertically
            padding:
                const EdgeInsets.only(left: 11, right: 0, top: 12, bottom: 12),
            child: Image.asset("assets/images/drawnArrow2.png", height: 32),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Text("I have a VPN subscription",
                  textAlign: TextAlign.left,
                  style: AppText.hopsInstructionsCallout),
            ),
          ),
        ],
      ),
    ));
  }

  // TODO: Factor out error handling with import/export page when we have it settled.
  void _importQRCode(BuildContext context) async {
    try {
      String text = await BarcodeScanner.scan();
      if (OrchidVPNConfigValidation.configValid(text)) {
        // successfully scanned config...
        _confirmImport(context, text);
      } else {
        _importError();
      }
    } on PlatformException catch (e) {
      print("barcode platform exception: $e");
      if (e.code == BarcodeScanner.CameraAccessDenied) {
        // 'The user did not grant the camera permission!';
        // TODO: Offer to send the user back to settings?
      } else {
        // 'Unknown error
      }
    } on FormatException {
      // 'null (User returned using the "back"-button before scanning anything. Result)'
      print("barcode format exception");
    } catch (e) {
      // 'Unknown error
      print("barcode unknown exception: $e");
    }
  }

  void _importError() {
    Dialogs.showAppDialog(
        context: context,
        title: "Invalid QR Code",
        bodyText:
        "The QR code you scanned does not contain a valid configuration.");
  }

  void _confirmImport(BuildContext context, String text) async {
    // If there are no existing hops add the config without confirmation
    var hops = (await UserPreferences().getCircuit())?.hops ?? [];
    if (hops.isEmpty) {
      _importConfig(context, text);
    } else {
      Dialogs.showConfirmationDialog(
          context: context,
          title: "Confirm Import",
          body: "The import you scanned is a complete hops configuration. "
              "Saving it will replace any existing hops that you had previously configured.  "
              "Are you sure you want to import this hop configuration?",
          commitAction: () {
            _importConfig(context, text);
          });
    }
  }

  void _importConfig(BuildContext context, String config) async {
    await OrchidVPNConfig.importConfig(config);
    widget.onAddFlowComplete(null);
  }

  Divider _divider() =>
      Divider(color: Colors.black.withOpacity(0.3), height: 1.0);
}
