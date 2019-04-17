import 'package:flutter/material.dart';
import 'package:orchid/api/user_preferences.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_gradients.dart';
import 'package:orchid/pages/app_text.dart';
import 'package:orchid/pages/common/accomodate_keyboard.dart';
import 'package:orchid/pages/common/app_bar.dart';
import 'package:orchid/pages/common/link_text.dart';
import 'package:orchid/pages/onboarding/onboarding.dart';
import 'package:orchid/pages/onboarding/walkthrough_content.dart';
import 'package:orchid/pages/settings/wallet_key_entry.dart';

class OnboardingLinkWalletPage extends StatefulWidget {
  @override
  _OnboardingLinkWalletPageState createState() =>
      _OnboardingLinkWalletPageState();
}

class _OnboardingLinkWalletPageState extends State<OnboardingLinkWalletPage> {
  WalletKeyEntryController _walletKeyEntryController =
      WalletKeyEntryController();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: SmallAppBar.build(context),
      body: Container(
          decoration:
              BoxDecoration(gradient: AppGradients.verticalGrayGradient1),
          child: AccommodateKeyboard(
            child: Column(
              children: <Widget>[
                // For large screens distribute the space a bit, else fixed margin.
                screenWidth > 640 ? Spacer(flex: 1) : SizedBox(height: 48),
                buildDescription(),
                SizedBox(height: 68),
                WalletKeyEntry(controller: _walletKeyEntryController),
                SizedBox(height: 20),
                Spacer(flex: 2),
                StreamBuilder<Object>(
                    stream: _walletKeyEntryController.readyToSave.stream,
                    builder: (context, snapshot) {
                      return NextSkipButtons.build(
                          onNext: _walletKeyEntryController.readyToSave.value
                              ? _next
                              : null,
                          onSkip: _skip);
                    })
              ],
            ),
          )),
    );
  }

  Widget buildDescription() {
    var titleText = "Link an external wallet";
    var bodyRichText = buildRichText();

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

  TextSpan buildRichText() {
    return TextSpan(
      children: <TextSpan>[
        TextSpan(
            text:
                "You need to link Orchid to an Ethereum wallet in order to use the Alpha."
                " Enter or scan a private key for the wallet you want to use to pay for bandwidth.",
            style: AppText.bodyStyle.copyWith(
                color: AppColors.neutral_2,
                letterSpacing: 0.25,
                // TODO: This is an approximation, the numbers in Zeplin would indicate 1.42 but
                // TODO: that appears way too large.
                height: 1.23)),
        TextSpan(text: "\n\n"),
        TextSpan(
          style: AppText.bodyStyle.copyWith(fontWeight: FontWeight.w700),
          text:
              "Make sure your wallet is on testnet and using test tokens while Orchid is in Alpha."
              " If you do not have an Ethereum wallet on testnet, you can set one up ",
        ),
        LinkTextSpan(
          text: "here.",
          style: AppText.bodyStyle
              .copyWith(fontWeight: FontWeight.w700, color: AppColors.teal_3),
          url: 'https://orchid.com',
        ),
      ],
    );
  }

  void _next() async {
    bool success = await _walletKeyEntryController.save();
    if (success) {
      _complete();
    }
  }

  void _skip() {
    _complete();
  }

  // Note that the user has viewed this screen and move on.
  void _complete() async {
    await UserPreferences().setPromptedToLinkWallet(true);
    AppOnboarding().pageComplete(context);
  }
}
