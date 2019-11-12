import 'package:flutter/material.dart';
import 'package:orchid/pages/help/help_feedback_page.dart';
import 'package:orchid/pages/help/help_page.dart';
import 'package:orchid/pages/connect/connect_page.dart';
import 'package:orchid/pages/help/open_source_page.dart';
import 'package:orchid/pages/help/privacy_page.dart';
import 'package:orchid/pages/monitoring/monitoring_page.dart';
import 'package:orchid/pages/onboarding/onboarding_link_wallet_page.dart';
import 'package:orchid/pages/onboarding/onboarding_link_wallet_success_page.dart';
import 'package:orchid/pages/onboarding/onboarding_vpn_credentials_page.dart';
import 'package:orchid/pages/onboarding/onboarding_vpn_permission_page.dart';
import 'package:orchid/pages/onboarding/walkthrough_pages.dart';
import 'package:orchid/pages/settings/configuration_page.dart';
import 'package:orchid/pages/settings/settings_dev_page.dart';
import 'package:orchid/pages/settings/settings_link_wallet_page.dart';
import 'package:orchid/pages/settings/settings_log_page.dart';
import 'package:orchid/pages/settings/settings_page.dart';
import 'package:orchid/pages/settings/settings_vpn_credentials_page.dart';
import 'budget/balance_page.dart';
import 'help/help_overview.dart';
import 'help/legal_page.dart';

class AppRoutes {
  static const String connect = "/connect";
  static const String settings = "/settings";
  static const String settings_wallet = "/settings/wallet";
  static const String settings_vpn = "/settings/vpn";
  static const String settings_log = "/settings/log";
  static const String settings_dev = "/settings/dev";
  static const String configuration = "/settings/configuration";
  static const String help = "/help";
  static const String help_overview = "/help/overview";
  static const String privacy = "/help/privacy";
  static const String open_source = "/help/open_source";
  static const String legal = "/legal";
  static const String feedback = "/feedback";
  static const String onboarding_walkthrough = "/onboarding/walkthrough";
  static const String onboarding_vpn_permission = "/onboarding/vpn_permission";
  static const String onboarding_link_wallet = "/onboarding/link_wallet";
  static const String onboarding_link_wallet_success = "/onboarding/link_wallet/success";
  static const String onboarding_vpn_credentials = "/onboarding/vpn_credentials";
  static const String balance = "/budget/balance";
  static const String budget_overview = "/budget/overview";
  static const String home = "/";

  static final Map<String, WidgetBuilder> routes = {
    //home: (context) => MonitoringPage(), // Don't define a home route when using tab layout.
    connect: (context) => QuickConnectPage(),
    settings: (context) => SettingsPage(),
    settings_wallet: (context) => SettingsLinkWalletPage(),
    settings_vpn: (context) => SettingsVPNCredentialsPage(),
    settings_log: (context) => SettingsLogPage(),
    settings_dev: (context) => SettingsDevPage(),
    configuration: (context) => ConfigurationPage(),
    help: (context) => HelpPage(),
    help_overview: (context) => HelpOverviewPage(),
    privacy: (context) => PrivacyPage(),
    open_source: (context) => OpenSourcePage(),
    legal: (context) => LegalPage(),
    feedback: (context) => HelpFeedbackPage(),
    onboarding_walkthrough: (context) => WalkthroughPages(),
    onboarding_vpn_permission: (context) => OnboardingVPNPermissionPage(),
    onboarding_link_wallet: (context) => OnboardingLinkWalletPage(),
    onboarding_link_wallet_success: (context) => OnboardingLinkWalletSuccessPage(),
    onboarding_vpn_credentials: (context) => OnboardingVPNCredentialsPage(),
    balance: (context) => BalancePage(),
  };
}
