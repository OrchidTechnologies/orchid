import 'package:flutter/material.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/common/app_dialogs.dart';
import 'package:orchid/util/localization.dart';

class ConfigChangeDialogs {
  static Future<void> showConfigurationChangeSuccess(BuildContext context,
      {bool warnOnly = false}) {
    var warn;
    switch (OrchidAPI().vpnRoutingStatus.value) {
      case OrchidVPNRoutingState.VPNNotConnected:
      case OrchidVPNRoutingState.VPNDisconnecting:
        warn = false;
        break;
      case OrchidVPNRoutingState.VPNConnecting:
      case OrchidVPNRoutingState.OrchidConnected:
      case OrchidVPNRoutingState.VPNConnected:
        warn = true;
    }
    if (warnOnly && !warn) {
      return Future.value();
    }
    var warning = warn ? context.s.changesWillTakeEffectInstruction : "";
    return AppDialogs.showAppDialog(
        context: context,
        title: context.s.saved + '!',
        bodyText: context.s.configurationSaved + " " + warning);
  }

  static void showConfigurationChangeFailed(BuildContext context,
      {String? errorText}) {
    AppDialogs.showAppDialog(
        context: context,
        title: context.s.whoops + '!',
        bodyText: context.s.configurationFailedInstruction +
            (errorText != null ? '\n\n' + errorText : ""));
  }
}
