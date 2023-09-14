import 'package:flutter/material.dart';
import 'package:orchid/pages/help/open_source_page.dart';
import 'package:orchid/pages/help/privacy_page.dart';
import 'package:orchid/pages/settings/advanced_configuration_page.dart';
import 'package:orchid/pages/settings/manage_config_page.dart';
import 'package:orchid/pages/settings/logging_page.dart';
import 'package:orchid/pages/settings/rpc_page.dart';
import 'package:orchid/pages/settings/settings_page.dart';
import 'account_manager/account_manager_page.dart';
import 'circuit/circuit_page.dart';
import 'help/help_overview.dart';
import 'help/legal_page.dart';
import 'monitoring/traffic_view.dart';

class AppRoutes {
  static const String connect = "/connect";
  static const String settings = "/settings";
  static const String settings_wallet = "/settings/wallet";
  static const String settings_vpn = "/settings/vpn";
  static const String settings_log = "/settings/log";
  static const String settings_dev = "/settings/dev";
  static const String settings_rpc = "/settings/rpc";
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
  static const String onboarding_link_wallet_success =
      "/onboarding/link_wallet/success";
  static const String onboarding_vpn_credentials =
      "/onboarding/vpn_credentials";
  static const String manage_config = "/settings/manage_config";
  static const String circuit = "/circuit";
  static const String account_manager = "/identity";
  static const String traffic = "/traffic";
  static const String accounts = "/settings/accounts";
  static const String home = "/";

  static final Map<String, WidgetBuilder> routes = {
    settings: (context) => SettingsPage(),
    settings_log: (context) => LoggingPage(),
    settings_rpc: (context) => RpcPage(),
    configuration: (context) => AdvancedConfigurationPage(),
    help_overview: (context) => HelpOverviewPage(),
    privacy: (context) => PrivacyPage(),
    open_source: (context) => OpenSourcePage(),
    legal: (context) => LegalPage(),
    circuit: (context) => CircuitPage(),
    traffic: (context) => TrafficView(),
    manage_config: (context) => ManageConfigPage(),
    account_manager: (context) => AccountManagerPage()
  };

  static Future<void> pushAccountManager(BuildContext context) async {
    await Navigator.pushNamed(context, AppRoutes.account_manager);
  }
}
