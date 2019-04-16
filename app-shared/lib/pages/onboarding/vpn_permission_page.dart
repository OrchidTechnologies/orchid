import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_gradients.dart';
import 'package:orchid/pages/common/app_bar.dart';
import 'package:orchid/pages/common/app_buttons.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/onboarding/app_onboarding.dart';
import 'package:orchid/pages/onboarding/walkthrough_content.dart';

class VPNPermissionPage extends StatefulWidget {
  @override
  _VPNPermissionPageState createState() => _VPNPermissionPageState();
}

class _VPNPermissionPageState extends State<VPNPermissionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmallAppBar.build(context),
      body: Container(
          decoration:
              BoxDecoration(gradient: AppGradients.verticalGrayGradient1),
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: WalkthroughContent(
                  imageAtBottom: true,
                  titleText: "Let's get you set up",
                  bodyText:
                      "To fully utilize Orchid, you will need to grant permission for the VPN connection. Next up, you will see a dialog asking you to allow this connection.",
                  imageName: 'assets/images/illustration_4.png',
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                        width: 180,
                        child: RoundedRectRaisedButton(
                          text: 'NEXT',
                          onPressed: _confirmNext,
                        )),
                  ),
                  SizedBox(height: 4),
                  LinkStyleTextButton(
                    "I'll do this later",
                    onPressed: _skip,
                  ),
                  SizedBox(height: 12)
                ],
              )
            ],
          )),
    );
  }

  // Show a confirmation dialog
  void _confirmNext() {
    Dialogs.showConfirmationDialog(
        context: context,
        title: "Allow Connection",
        body:
            "Orchid VPN is requesting permission to set up a VPN connection that will"
            " allow it to monitor network traffic. Only allow this if you trust this source."
            "\n\nAn icon will be shown at the top of your screen while the VPN is in use. Allow?",
        cancelText: "CANCEL",
        //cancelColor: AppColors.purple_3,
        actionText: "OK",
        //actionColor: AppColors.purple_3,
        action: () {
          _next();
        });
  }

  // Accept the permission check.
  void _next() async {
    bool ok = await OrchidAPI().requestVPNPermission();
    if (ok) {
      _complete();
    }
  }

  // Skip the permission check for now.
  void _skip() {
    _complete();
  }

  // Note that the user has viewed this screen and move on.
  void _complete() async {
    await UserPreferences().setPromptedForVPNPermission(true);
    AppOnboarding().pageComplete(context);
  }
}
