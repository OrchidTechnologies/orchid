import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/common/app_sizes.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/orchid/orchid_gradients.dart';
import 'package:orchid/orchid/orchid_panel.dart';
import 'package:orchid/orchid/orchid_text.dart';
import 'package:orchid/pages/circuit/hop_editor.dart';
import 'package:orchid/pages/circuit/wireguard_hop_page.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/vpn/model/circuit_hop.dart';
import 'openvpn_hop_page.dart';
import 'orchid_hop_page.dart';
import 'package:orchid/util/localization.dart';

typedef AddFlowCompletion = void Function(CircuitHop? result);

class AddHopPage extends StatefulWidget {
  final AddFlowCompletion onAddFlowComplete;

  const AddHopPage({Key? key, required this.onAddFlowComplete})
      : super(key: key);

  @override
  _AddHopPageState createState() => _AddHopPageState();
}

class _AddHopPageState extends State<AddHopPage> {
  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {}

  @override
  Widget build(BuildContext context) {
    return TitledPage(
      title: s.addHop,
      cancellable: true,
      backAction: () {
        widget.onAddFlowComplete(null);
      },
      // decoration: BoxDecoration(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (AppSize(context).tallerThan(AppSize.iphone_12_pro_max))
                      pady(64),
                    pady(32),
                    Text(
                      s.orchidIsUniqueAsAMultiHopOrOnion,
                      textAlign: TextAlign.left,
                      style: OrchidText.body2,
                    ),
                    pady(24),

                    // Account Chooser
                    // if (!OrchidPlatform.isApple) ...[
                    pady(24),
                    _buildHopChoice(
                      text: s.useAnOrchidAccount,
                      onTap: () {
                        _addHopType(HopProtocol.Orchid);
                      },
                      imageName: OrchidAssetImage.logo_small_purple_path,
                    ),
                    // ],

                    // OVPN Subscription
                    pady(24),
                    _buildHopChoice(
                      text: s.enterOpenvpnConfig,
                      onTap: () {
                        _addHopType(HopProtocol.OpenVPN);
                      },
                      svgName: OrchidAssetSvg.openvpn_path,
                    ),

                    // WireGuard
                    pady(24),
                    _buildHopChoice(
                      text: s.enterWireguardConfig,
                      onTap: () {
                        _addHopType(HopProtocol.WireGuard);
                      },
                      svgName: OrchidAssetSvg.wireguard_path,
                    ),

                    pady(96),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHopChoice(
      {required String text,
      String? imageName,
      String? svgName,
      VoidCallback? onTap,
      Widget? trailing}) {
    if (imageName == null && svgName == null) {
      throw Exception('Must provide either imageName or svgName');
    }
    return GestureDetector(
      onTap: onTap,
      child: OrchidPanel(
        edgeGradient: OrchidGradients.orchidPanelEdgeGradientMoreVertical,
        child: Padding(
          padding:
              const EdgeInsets.only(top: 16, bottom: 16, left: 16, right: 16),
          child: Row(children: [
            (svgName != null
                ? SvgPicture.asset(svgName,
                    width: 24, height: 24, color: Colors.white)
                : Image.asset(imageName!,
                    width: 24, height: 24, color: Colors.white)),
            padx(16),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.left,
                style: OrchidText.button.copyWith(fontSize: 19, height: 1.7),
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: Colors.white),
          ]),
        ),
      ),
    );
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
      case HopProtocol.WireGuard:
        editor = WireGuardHopPage(
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
  /*
  void _addHopFromPACPurchase() async {
    var route = MaterialPageRoute<CircuitHop>(builder: (BuildContext context) {
      return PurchasePageV0(onAddFlowComplete: widget.onAddFlowComplete);
    });
    _pushCircuitBuilderRoute(route);
  }*/

  // Push the editor or other builder that returns a circuit hop.
  void _pushCircuitBuilderRoute(MaterialPageRoute<CircuitHop> route) async {
    // If the editor invokes the addFlowComplete, which should be the case on a save,
    // this entire flow will be popped to the caller and control will not return here.
    CircuitHop? hop = await Navigator.push(context, route);
    // If hop is null the user backed out of the editor: Fall through and allow another choice.
    if (hop != null) {
      // Handle a return here for completeness.
      Navigator.pop(context, hop);
    }
  }
}
