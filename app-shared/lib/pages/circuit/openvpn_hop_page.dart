import 'package:flutter/material.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_colors.dart';
import '../app_text.dart';
import 'circuit_hop.dart';

/// Create / edit / view an Open VPN Hop
class OpenVPNHopPage extends HopEditor<OpenVPNHop> {
  OpenVPNHopPage(
      {@required editableHop, mode = HopEditorMode.View, onAddFlowComplete})
      : super(
            editableHop: editableHop,
            mode: mode,
            onAddFlowComplete: onAddFlowComplete);

  @override
  _OpenVPNHopPageState createState() => _OpenVPNHopPageState();
}

class _OpenVPNHopPageState extends State<OpenVPNHopPage> {
  // TODO: Validation logic
  var _userName = TextEditingController();
  var _userPassword = TextEditingController();
  var _ovpnConfig = TextEditingController();

  @override
  void initState() {
    super.initState();
    OpenVPNHop hop = widget.editableHop.value?.hop;
    _userName.text = hop?.userName;
    _userPassword.text = hop?.userPassword;
    _ovpnConfig.text = hop?.ovpnConfig;
    setState(() {}); // Setstate to update the hop for any defaulted values.

    _userName.addListener(_updateHop);
    _userPassword.addListener(_updateHop);
    _ovpnConfig.addListener(_updateHop);
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _updateHop();
  }

  @override
  Widget build(BuildContext context) {
    return TapClearsFocus(
      child: TitledPage(
        title: "Open VPN Hop",
        actions: widget.mode == HopEditorMode.Create
            ? [widget.buildSaveButton(context)]
            : [],
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SafeArea(
            child: Column(
              children: <Widget>[
                pady(16),
                Row(
                  children: <Widget>[
                    Text("User name:",
                        style: AppText.textLabelStyle.copyWith(fontSize: 20)),
                    Expanded(child: AppTextField(controller: _userName))
                  ],
                ),
                pady(16),
                Row(
                  children: <Widget>[
                    Text("Password:",
                        style: AppText.textLabelStyle.copyWith(fontSize: 20)),
                    Expanded(child: AppTextField(controller: _userPassword))
                  ],
                ),

                // opvn config
                pady(16),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Config:",
                        style: AppText.textLabelStyle.copyWith(fontSize: 20))),
                // TODO: This is copied from the configuration page, factor out?
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 24, bottom: 24),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: SingleChildScrollView(
                          child: TextFormField(
                        autocorrect: false,
                        autofocus: false,
                        keyboardType: TextInputType.multiline,
                        style:
                            AppText.logStyle.copyWith(color: AppColors.grey_2),
                        controller: _ovpnConfig,
                        maxLines: 99999,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelStyle: AppText.textLabelStyle,
                        ),
                      )),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        border:
                            Border.all(width: 2.0, color: AppColors.neutral_5),
                      ),
                    ),
                  ),
                )
              ],
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
    widget.editableHop.update(OpenVPNHop(
        userName: _userName.text,
        userPassword: _userPassword.text,
        ovpnConfig: _ovpnConfig.text));
  }

  @override
  void dispose() {
    super.dispose();
    _userName.removeListener(_updateHop);
    _userPassword.removeListener(_updateHop);
    _ovpnConfig.removeListener(_updateHop);
  }
}
