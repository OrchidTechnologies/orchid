import 'package:flutter/material.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/instructions_view.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_colors.dart';
import '../app_text.dart';
import 'hop_editor.dart';
import 'model/openvpn_hop.dart';

/// Create / edit / view an OpenVPN Hop
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
  var _userName = TextEditingController();
  var _userPassword = TextEditingController();
  var _ovpnConfig = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Disable rotation until we update the screen design
    ScreenOrientation.portrait();

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
    double screenHeight = MediaQuery.of(context).size.height;
    return TapClearsFocus(
      child: TitledPage(
        title: s.openVPNHop,
        actions: widget.mode == HopEditorMode.Create
            ? [widget.buildSaveButton(context, widget.onAddFlowComplete)]
            : [],
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: <Widget>[
                  _buildUserName(),
                  _buildPassword(),
                  pady(16),
                  // OPVN Config
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(s.config + ":",
                          style: AppText.textLabelStyle.copyWith(fontSize: 20))),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Container(
                      height: screenHeight/2.8,
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextFormField(
                        autocorrect: false,
                        autofocus: false,
                        smartQuotesType: SmartQuotesType.disabled,
                        smartDashesType: SmartDashesType.disabled,
                        keyboardType: TextInputType.multiline,
                        style:
                        AppText.logStyle.copyWith(color: AppColors.grey_2),
                        controller: _ovpnConfig,
                        maxLines: 99999,
                        decoration: InputDecoration(
                      hintText: s.pasteYourOVPN,
                      border: InputBorder.none,
                      labelStyle: AppText.textLabelStyle,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        border:
                            Border.all(width: 2.0, color: AppColors.neutral_5),
                      ),
                    ),
                  ),

                  // Instructions
                  Visibility(
                    visible: widget.mode == HopEditorMode.Create,
                    child: InstructionsView(
                      // TODO: This screen is being told it's in landscape mode in the simulator?
                      //hideInLandscape: false,
                      title: s.enterYourCredentials,
                      body: s.enterLoginInformationInstruction + " ",
                    ),
                  ),
                  pady(24)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column _buildPassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        pady(16),
        Text(s.password + ":",
            style: AppText.textLabelStyle.copyWith(fontSize: 20)),
        pady(8),
        AppTextField(
            hintText: s.password,
            margin: EdgeInsets.zero,
            controller: _userPassword)
      ],
    );
  }

  Column _buildUserName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        pady(16),
        Text(s.username + ":",
            style: AppText.textLabelStyle.copyWith(fontSize: 20)),
        pady(8),
        AppTextField(
            hintText: s.username,
            margin: EdgeInsets.zero,
            controller: _userName)
      ],
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
    ScreenOrientation.reset();
    _userName.removeListener(_updateHop);
    _userPassword.removeListener(_updateHop);
    _ovpnConfig.removeListener(_updateHop);
  }

  S get s {
    return S.of(context);
  }
}
