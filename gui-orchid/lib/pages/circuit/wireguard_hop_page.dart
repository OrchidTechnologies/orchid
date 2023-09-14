import 'package:flutter/material.dart';
import 'package:orchid/common/config_text.dart';
import 'package:orchid/common/formatting.dart';
import 'package:orchid/common/instructions_view.dart';
import 'package:orchid/common/screen_orientation.dart';
import 'package:orchid/common/tap_clears_focus.dart';
import 'package:orchid/orchid/orchid_titled_page_base.dart';
import 'package:orchid/vpn/model/wireguard_hop.dart';
import '../../common/app_sizes.dart';
import 'hop_editor.dart';
import 'package:orchid/util/localization.dart';

/// Create / edit / view an WireGuard Hop
class WireGuardHopPage extends HopEditor<WireGuardHop> {
  WireGuardHopPage(
      {required editableHop, mode = HopEditorMode.View, onAddFlowComplete})
      : super(
            editableHop: editableHop,
            mode: mode,
            onAddFlowComplete: onAddFlowComplete);

  @override
  _WireGuardHopPageState createState() => _WireGuardHopPageState();
}

class _WireGuardHopPageState extends State<WireGuardHopPage> {
  var _config = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Disable rotation until we update the screen design
    ScreenOrientation.portrait();

    // CircuitHop? hop = widget.editableHop.value?.hop;
    // TODO: Intellij isn't showing this type as nullable...?
    WireGuardHop? hop = widget.editableHop.value?.hop as WireGuardHop;
    setState(() {
      _config.text = hop?.config ?? '';
    }); // Setstate to update the hop for any defaulted values.
    _config.addListener(_updateHop);
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _updateHop();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return TapClearsFocus(
      child: TitledPage(
        title: s.wireguardHop,
        // decoration: BoxDecoration(),
        actions: widget.mode == HopEditorMode.Create
            ? [widget.buildSaveButton(context, widget.onAddFlowComplete)]
            : [],
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 700),
                  child: Column(
                    children: <Widget>[
                      if (AppSize(context).tallerThan(AppSize.iphone_12_pro_max))
                        pady(64),
                      pady(16),
                      ConfigLabel(text: s.config),
                      ConfigText(
                        height: screenHeight / 2.8,
                        textController: _config,
                        hintText: s.pasteYourWireguardConfigFileHere,
                      ),

                      // Instructions
                      Visibility(
                        visible: widget.mode == HopEditorMode.Create,
                        child: InstructionsView(
                          title: s.enterYourCredentials,
                          body:
                              s.pasteTheCredentialInformationForYourWireguardProviderIntoThe,
                        ),
                      ),
                      pady(24)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateHop() {
    if (!widget.editable()) {
      return;
    }
    widget.editableHop.update(WireGuardHop(config: _config.text));
  }

  @override
  void dispose() {
    super.dispose();
    ScreenOrientation.reset();
    _config.removeListener(_updateHop);
  }
}
