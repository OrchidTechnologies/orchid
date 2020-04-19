import 'package:flutter/material.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_gradients.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/accommodate_keyboard.dart';
import 'package:orchid/pages/common/app_bar.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/onboarding/onboarding.dart';
import 'package:orchid/pages/onboarding/walkthrough_content.dart';
import 'package:orchid/pages/onboarding/walkthrough_pages.dart';
import 'package:orchid/pages/settings/vpn_credentials_entry.dart';

class OnboardingVPNCredentialsPage extends StatefulWidget {
  @override
  _OnboardingVPNCredentialsPageState createState() =>
      _OnboardingVPNCredentialsPageState();
}

class _OnboardingVPNCredentialsPageState
    extends State<OnboardingVPNCredentialsPage> {
  VPNCredentialsEntryController _vpnCredentialsEntryController =
      VPNCredentialsEntryController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmallAppBar(),
      body: Container(
          decoration:
              BoxDecoration(gradient: AppGradients.verticalGrayGradient1),
          child: AccommodateKeyboard(
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  // For large screens distribute the space a bit, else fixed margin.
                  WalkthroughPages.TopContentPadding.value(context),
                  _VPNCredentialsDescription(),
                  SizedBox(height: 68),
                  VPNCredentialsEntry(
                      controller: _vpnCredentialsEntryController),
                  SizedBox(height: 20),
                  Spacer(flex: 2),
                  StreamBuilder<Object>(
                      stream: _vpnCredentialsEntryController.readyToSave.stream,
                      builder: (context, snapshot) {
                        return WalkthroughNextSkipButtons(
                          onNext:
                              _vpnCredentialsEntryController.readyToSave.value
                                  ? _next
                                  : null,
                          onSkip: _skip,
                          bottomPad:
                              WalkthroughPages.BottomControlsPadding.value(
                                  context),
                        );
                      })
                ],
              ),
            ),
          )),
    );
  }

  void _next() async {
    bool success = await _vpnCredentialsEntryController.save();
    if (success) {
      _complete();
    }
  }

  void _skip() {
    _complete();
  }

  // Note that the user has viewed this screen and move on.
  void _complete() async {
    await UserPreferences().setPromptedForVPNCredentials(true);
    AppOnboarding().pageComplete(context);
  }
}

class _VPNCredentialsDescription extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var titleText = "VPN Login";
    var bodyRichText = TextSpan(
      children: <TextSpan>[
        TextSpan(
            text:
                "For Alpha, we have partnered with [VPN Partner]. Enter your login credentials below "
                "and Orchid will pair you with the best available server. "
                "If you don't have an account with [VPN Provider], you can sign up for a free trial.",
            style: AppText.onboardingBodyStyle),
        LinkTextSpan(
          text: "here.",
          style: AppText.linkStyle,
          url: 'https://orchid.com',
        ),
      ],
    );

    var headerTextBox = new WalkthroughHeaderTextBox(titleText: titleText);
    var bodyTextBox = new WalkthroughBodyTextBox(bodyRichText: bodyRichText);

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Center(
          child: Column(
            children: <Widget>[
              headerTextBox,
              SizedBox(height: 20),
              bodyTextBox,
            ],
          ),
        ));
  }
}
