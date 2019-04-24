import 'package:flutter/material.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_gradients.dart';
import 'package:orchid/pages/common/app_bar.dart';
import 'package:orchid/pages/onboarding/onboarding.dart';
import 'package:orchid/pages/onboarding/walkthrough_content.dart';

class OnboardingLinkWalletSuccessPage extends StatefulWidget {
  @override
  _OnboardingLinkWalletSuccessPageState createState() =>
      _OnboardingLinkWalletSuccessPageState();
}

class _OnboardingLinkWalletSuccessPageState
    extends State<OnboardingLinkWalletSuccessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmallAppBar.build(context),
      body: Container(
          decoration:
              BoxDecoration(gradient: AppGradients.verticalGrayGradient1),
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                // Center horizontally (walkthrough content fills screen vertically)
                Center(
                  child: WalkthroughContent(
                    imageLocation: WalkthroughContentImageLocation.Bottom,
                    titleText: "Wallet linked!",
                    bodyText:
                        "You have successfully linked an Ethereum wallet to Orchid and "
                        "will use this wallet to pay for bandwidth going forward.\n\n"
                        "You may change or add an external wallet at any time from within the settings tab.",
                    imageName: 'assets/images/illustration_5.png',
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child:
                      Padding(
                        padding: const EdgeInsets.only(bottom: 42),
                        child: NextSkipButtons.buildNextButton(onNext: _complete),
                      ),
                )
              ],
            ),
          )),
    );
  }

  // Note that the user has viewed this screen and move on.
  void _complete() async {
    await UserPreferences().setLinkWalletAcknowledged(true);
    AppOnboarding().pageComplete(context);
  }
}

