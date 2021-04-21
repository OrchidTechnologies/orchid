import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/pages/app_routes.dart';
import 'package:orchid/common/app_transitions.dart';
import 'package:orchid/pages/onboarding/onboarding_vpn_permission_page.dart';
import 'package:orchid/pages/onboarding/walkthrough_pages.dart';

class AppOnboarding {
  static final AppOnboarding _singleton = AppOnboarding._internal();
  static final String NO_PAGE = null;

  AppOnboarding._internal() {
    debugPrint("constructed app onboarding singleton");
  }

  factory AppOnboarding() {
    return _singleton;
  }

  Future<void> reset() async {
    await UserPreferences().setPromptedForVPNPermission(false);
    await OrchidAPI().clearWallet();
    OrchidAPI().vpnPermissionStatus.add(false);
  }

  /// Return the route for the next remaining page in the onboarding sequence or
  /// null if no pages remain to be shown.
  Future<String> _nextPage() async {

    /*
    // Show the walkthrough
    bool walkthroughCompleted = await UserPreferences().getWalkthroughCompleted();
    if (!walkthroughCompleted) {
      return AppRoutes.onboarding_walkthrough;
    }

    // Prompt for VPN permission
    // TODO: race condition here.
    bool hasVPNPermission = OrchidAPI().vpnPermissionStatus.value;
    bool promptedForVPNPermission = await UserPreferences().getPromptedForVPNPermission();
    debugPrint("XXX: hasVPNPerm: $hasVPNPermission, prompted: $promptedForVPNPermission");
    if (!(hasVPNPermission == true) && !promptedForVPNPermission) {
      return AppRoutes.onboarding_vpn_permission;
    }
    */

    return NO_PAGE;
  }

  /// Display the the next, if any, in the sequence of onboarding pages remaining
  /// to be shown to the user.
  Future<void> showPageIfNeeded(BuildContext context) async {
    String nextPage = await _nextPage();
    if (nextPage != NO_PAGE) {
      showPage(context, nextPage);
    }
  }

  /// This method is called by a page in the onboarding flow upon completion.
  /// If the the onboarding sequence is complete the calling page will be popped,
  /// ending the onboarding flow and returning control to the application pages on
  /// the stack. If pages remain in the onboarding sequence then the calling page
  /// will be replaced by the next page in the flow.
  Future<void> pageComplete(BuildContext context) async {
    var nextPage = await _nextPage();
    if (nextPage != NO_PAGE) {
      return showPage(context, nextPage, replace: true);
    } else {
      // onboarding complete
      return Navigator.pop(context);
      //return Navigator.popUntil(context, ModalRoute.withName('/'));
    }
  }

  // TODO: Currently applying custom transitions here.
  // TODO: We should be able to encapsulate these in AppRoutes.
  static void showPage(BuildContext context, String nextPage,
      {bool replace = false}) async {
    PageRouteBuilder route;
    switch (nextPage) {
      case AppRoutes.onboarding_walkthrough:
        route = AppTransitions.downToUpTransition(WalkthroughPages());
        break;
      case AppRoutes.onboarding_vpn_permission:
        route = AppTransitions.downToUpTransition(OnboardingVPNPermissionPage());
        break;
      default:
        break;
    }

    if (route != null) {
      if (replace) {
        await Navigator.pop(context);
        Navigator.push(context, route);
        //Navigator.pushReplacement(context, route);
      } else {
        Navigator.push(context, route);
      }
    } else {
      if (replace) {
        await Navigator.pop(context);
        Navigator.pushNamed(context, nextPage);
        //Navigator.pushReplacementNamed(context, nextPage);
      } else {
        Navigator.pushNamed(context, nextPage);
      }
    }
  }
}
