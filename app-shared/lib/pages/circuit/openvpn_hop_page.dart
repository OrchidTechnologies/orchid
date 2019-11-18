import 'package:flutter/material.dart';
import 'package:orchid/pages/common/app_text_field.dart';
import 'package:orchid/pages/common/formatting.dart';
import 'package:orchid/pages/common/tap_clears_focus.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import '../app_colors.dart';
import '../app_text.dart';
import 'circuit_hop.dart';

class OpenVPNHopPage extends StatefulWidget {
  final OpenVPNHop initialState;

  OpenVPNHopPage({this.initialState});

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
    _userName.text = widget.initialState?.userName;
    _userPassword.text = widget.initialState?.userPassword;
    _ovpnConfig.text = widget.initialState?.ovpnConfig;
  }

  @override
  Widget build(BuildContext context) {
    return TapClearsFocus(
      child: TitledPage(
        backAction: _backAction,
        title: "Open VPN Hop",
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

  void _backAction() {
    Navigator.pop(
        context,
        UniqueHop(
            key: DateTime.now().millisecondsSinceEpoch,
            hop: OpenVPNHop(
                userName: _userName.text,
                userPassword: _userPassword.text,
                ovpnConfig: _ovpnConfig.text)));
  }
}
