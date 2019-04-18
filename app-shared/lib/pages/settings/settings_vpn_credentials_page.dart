import 'package:flutter/material.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/accomodate_keyboard.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/titled_page_base.dart';
import 'package:orchid/pages/settings/vpn_credentials_entry.dart';

class SettingsVPNCredentialsPage extends StatefulWidget {
  @override
  _SettingsVPNCredentialsPage createState() => _SettingsVPNCredentialsPage();
}

class _SettingsVPNCredentialsPage extends State<SettingsVPNCredentialsPage> {
  VPNCredentialsEntryController _vpnCredentialsEntryController =
      VPNCredentialsEntryController();

  @override
  Widget build(BuildContext context) {
    return TitledPage(title: "VPN credentials", child: buildPage(context));
  }

  @override
  Widget buildPage(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return AccommodateKeyboard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          screenWidth > 640 ? Spacer(flex: 1) : Container(),

          // Explanatory text
          Padding(
              padding:
                  EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 15),
              child: AppText.body(
                textAlign: TextAlign.left,
                text: "For Alpha, we have partnered with [VPN Partner]. "
                    "Enter your login credentials below and when you connect Orchid "
                    "will pair you with the best available server.",
              )),

          // Explanatory text
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                children: <TextSpan>[
                  TextSpan(
                    style: AppText.bodyStyle,
                    text: "Don't have a [VPN Partner] account?\n",
                  ),
                  LinkTextSpan(
                    text: "Sign up for a free trial.",
                    style: AppText.bodyStyle.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.teal_3),
                    url: 'https://orchid.com',
                  ),
                ],
              ),
            ),
          ),

          // Form title
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 16),
            child: AppText.header(
                textAlign: TextAlign.left,
                text: "[VPN Partner] credentials",
                fontSize: 16.0),
          ),

          // Form fields
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child:
                VPNCredentialsEntry(controller: _vpnCredentialsEntryController),
          ),

          Spacer(), // Position remaining at the bottom
          SizedBox(height: 24),
          Spacer(flex: 3),

          // Save button
          Center(
            child: Container(
              margin: EdgeInsets.only(bottom: 62),
              child: StreamBuilder<Object>(
                stream: _vpnCredentialsEntryController.readyToSave.stream,
                builder: (context, snapshot) {
                  return RoundedRectRaisedButton(
                      text: "SAVE",
                      onPressed: _vpnCredentialsEntryController.readyToSave.value
                          ? _vpnCredentialsEntryController.save
                          : null);
                }
              ),
            ),
          ),
        ],
      ),
    );
  }
}


