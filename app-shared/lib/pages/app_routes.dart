import 'package:flutter/material.dart';
import 'package:orchid/pages/help/feedback_page.dart';
import 'package:orchid/pages/help/help_page.dart';
import 'package:orchid/pages/connect/quick_connect_page.dart';
import 'package:orchid/pages/onboarding/walkthrough_pages.dart';
import 'package:orchid/pages/settings/settings_dev_page.dart';
import 'package:orchid/pages/settings/settings_link_wallet_page.dart';
import 'package:orchid/pages/settings/settings_log_page.dart';
import 'package:orchid/pages/settings/settings_page.dart';
import 'package:orchid/pages/settings/settings_vpn_credentials_page.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => QuickConnectPage(),
    '/settings': (context) => SettingsPage(),
    '/settings/wallet': (context) => SettingsLinkWalletPage(),
    '/settings/vpn': (context) => SettingsVPNCredentialsPage(),
    '/settings/log': (context) => SettingsLogPage(),
    '/settings/dev': (context) => SettingsDevPage(),
    '/help': (context) => HelpPage(),
    '/feedback': (context) => FeedbackPage(),
    '/walkthrough': (context) => WalkthroughPages(),
  };
}
