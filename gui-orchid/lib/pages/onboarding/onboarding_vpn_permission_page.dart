import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/app_gradients.dart';
import 'package:orchid/pages/common/app_bar.dart';
import 'package:orchid/pages/common/dialogs.dart';
import 'package:orchid/pages/onboarding/onboarding.dart';
import 'package:orchid/pages/onboarding/walkthrough_content.dart';
import 'package:orchid/pages/onboarding/walkthrough_pages.dart';

class OnboardingVPNPermissionPage extends StatefulWidget {
  final Function(bool) onComplete;
  final bool includeScaffold;
  final bool allowSkip;

  const OnboardingVPNPermissionPage(
      {Key key, this.onComplete, this.includeScaffold = true, this.allowSkip = false})
      : super(key: key);

  @override
  _OnboardingVPNPermissionPageState createState() =>
      _OnboardingVPNPermissionPageState();
}

class _OnboardingVPNPermissionPageState
    extends State<OnboardingVPNPermissionPage> {
  @override
  Widget build(BuildContext context) {
    var body = buildBody(context);
    return widget.includeScaffold
        ? Scaffold(appBar: SmallAppBar(), body: body)
        : body;
  }

  Container buildBody(BuildContext context) {
    return Container(
        decoration: BoxDecoration(gradient: AppGradients.verticalGrayGradient1),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              // Main content, fills the screen vertically centered horizontally.
              Center(
                child: WalkthroughContent(
                  imageLocation: WalkthroughContentImageLocation.Bottom,
                  titleText: "Let's get you set up",
                  bodyText:
                      "To fully utilize Orchid, you will need to grant permission for the VPN connection. Next up, you will see a dialog asking you to allow this connection.",
                  imageName: 'assets/images/illustration_4.png',
                ),
              ),

              // The next/skip buttons
              Align(
                alignment: Alignment.bottomCenter,
                child: WalkthroughNextSkipButtons(
                  onNext: _confirmNext,
                  onSkip: _skip,
                  allowSkip: widget.allowSkip,
                  bottomPad:
                      WalkthroughPages.BottomControlsPadding.value(context),
                ),
              )
            ],
          ),
        ));
  }

  // Show a confirmation dialog
  void _confirmNext() {
    AppDialogs.showConfirmationDialog(
        context: context,
        title: "Allow Connection",
        bodyText:
            "Orchid VPN is requesting permission to set up a VPN extension that will"
            " allow it to show you your network traffic. Only allow this if you trust this source."
            "\n\nAn icon will be shown at the top of your screen while the VPN is in use. Allow?",
        cancelText: "CANCEL",
        actionText: "OK",
        commitAction: () {
          _next();
        });
  }

  // Accept the permission check.
  void _next() async {
    bool ok = await OrchidAPI().requestVPNPermission();
    OrchidAPI().logger().write("requestVPNPermission returned: $ok");
    if (ok) {
      _complete(true);
    }
  }

  // Skip the permission check for now.
  void _skip() {
    _complete(false);
  }

  // Note that the user has viewed this screen and move on.
  void _complete(bool result) async {
    await UserPreferences().setPromptedForVPNPermission(true);
    if (widget.onComplete != null) {
      return widget.onComplete(result);
    }
    OrchidAPI().logger().write("dismissing vpn perm page");
    AppOnboarding().pageComplete(context);
  }
}
