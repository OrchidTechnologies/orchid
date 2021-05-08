import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/configuration/orchid_account_config/orchid_account_v1.dart';
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config_v0.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/scan_paste_dialog.dart';
import 'package:orchid/pages/circuit/wireguard_hop_page.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/titled_page_base.dart';
import '../../common/app_sizes.dart';
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
  // bool _showPACs = false;
  bool _showWireGuard = false;

  @override
  void initState() {
    super.initState();
    initStateAsync();
  }

  void initStateAsync() async {
    // _showPACs = (await OrchidPurchaseAPI().apiConfig()).enabled;
    _showWireGuard = true;
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
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (AppSize(context).tallerThan(AppSize.iphone_12_max))
                      pady(64),
                    pady(40),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Image.asset('assets/images/approach.png',
                          height: 100),
                    ),
                    pady(24),
                    Text(s.orchidIsUniqueAsItSupportsMultipleVPN,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            height: 1.12,
                            letterSpacing: -0.24,
                            color: Color(0xff504960))),
                    pady(24),

                    /*
                    // PAC Purchase
                    if (_showPACs) _divider(),
                    if (_showPACs)
                      _buildHopChoice(
                          text: s.buyOrchidAccount,
                          onTap: () {
                            _addHopFromPACPurchase();
                          },
                          svgName: 'assets/svg/attach_money.svg'),
                     */

                    // Link Account
                    _divider(),
                    _buildHopChoice(
                        text: s.linkAnOrchidAccount,
                        onTap: () {
                          return showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return ScanOrPasteDialog(
                                  onImportAccount:
                                      (ParseOrchidAccountResult result) async {
                                    var hop = await OrchidVPNConfigV0
                                        .importAccountAsHop(result.account);
                                    widget.onAddFlowComplete(hop);
                                  },
                                  v0Only: true,
                                );
                              });
                        },
                        imageName: 'assets/images/scan.png'),

                    // Custom Account
                    if (!OrchidPlatform.isApple) ...[
                      _divider(),
                      _buildHopChoice(
                          text: s.createACustomAccount,
                          onTap: () {
                            _addHopType(HopProtocol.Orchid);
                          },
                          imageName: 'assets/images/logo_small_purple.png'),
                    ],

                    // OVPN Subscription
                    _divider(),
                    _buildHopChoice(
                        text: s.enterOpenvpnConfig,
                        onTap: () {
                          _addHopType(HopProtocol.OpenVPN);
                        },
                        svgName: 'assets/svg/openvpn.svg'),

                    // WireGuard
                    if (_showWireGuard) ...[
                      _divider(),
                      _buildHopChoice(
                          text: s.enterWireguardConfig,
                          onTap: () {
                            _addHopType(HopProtocol.WireGuard);
                          },
                          svgName: 'assets/svg/wireguard.svg'),
                    ],

                    _divider(),
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
      {String text,
      String imageName,
      String svgName,
      VoidCallback onTap,
      Widget trailing}) {
    return ListTile(
        contentPadding: EdgeInsets.only(left: 0, right: 8, top: 8, bottom: 8),
        leading: svgName != null
            ? SvgPicture.asset(svgName, width: 24, height: 24)
            : Image.asset(imageName, width: 24, height: 24),
        trailing:
            trailing ?? Icon(Icons.chevron_right, color: Colors.deepPurple),
        title: Text(text,
            textAlign: TextAlign.left,
            style: const TextStyle(
                color: const Color(0xff3a3149),
                fontWeight: FontWeight.w400,
                fontFamily: 'SFProText',
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
