import 'package:flutter/material.dart';
import 'package:orchid/pages/help/feedback_page.dart';
import 'package:orchid/pages/help/help_page.dart';
import 'package:orchid/pages/connect/quick_connect_page.dart';
import 'package:orchid/pages/onboarding/vpn_permission_page.dart';
import 'package:orchid/pages/onboarding/walkthrough_pages.dart';
import 'package:orchid/pages/settings/settings_dev_page.dart';
import 'package:orchid/pages/settings/settings_link_wallet_page.dart';
import 'package:orchid/pages/settings/settings_log_page.dart';
import 'package:orchid/pages/settings/settings_page.dart';
import 'package:orchid/pages/settings/settings_vpn_credentials_page.dart';


class AppRoutes {

  static const String settings = "/settings";
  static const String settings_wallet = "/settings/wallet";
  static const String settings_vpn = "/settings/vpn";
  static const String settings_log = "/settings/log";
  static const String settings_dev = "/settings/dev";
  static const String help = "/help";
  static const String feedback = "/feedback";
  static const String onboarding_walkthrough = "/onboarding/walkthrough";
  static const String onboarding_vpn_permission = "/onboarding/vpn_permission";

  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => QuickConnectPage(),
    settings: (context) => SettingsPage(),
    settings_wallet: (context) => SettingsLinkWalletPage(),
    settings_vpn: (context) => SettingsVPNCredentialsPage(),
    settings_log: (context) => SettingsLogPage(),
    settings_dev: (context) => SettingsDevPage(),
    help: (context) => HelpPage(),
    feedback: (context) => FeedbackPage(),
    onboarding_walkthrough: (context) => WalkthroughPages(),
    onboarding_vpn_permission: (context) => VPNPermissionPage(),
  };
}
