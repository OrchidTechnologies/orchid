import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/config_text.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/instructions_view.dart';
import 'package:orchid/pages/common/screen_orientation.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_sizes.dart';
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
        decoration: BoxDecoration(),
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
                      if (AppSize(context).tallerThan(AppSize.iphone_12_max))
                        pady(64),
                      _buildUserName(),
                      _buildPassword(),
                      pady(16),
                      // OVPN Config
                      ConfigLabel(text: s.config),
                      ConfigText(
                        height: screenHeight / 2.8,
                        textController: _ovpnConfig,
                        hintText: s.pasteYourOVPN,
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

