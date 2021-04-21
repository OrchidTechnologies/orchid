import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_dialogs.dart';

class ConfigChangeDialogs {

  static Future<void> showConfigurationChangeSuccess(BuildContext context,
      {bool warnOnly = false}) {
    S s = S.of(context);
    var warn;
    switch (OrchidAPI().connectionStatus.value) {
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.VPNNotConnected:
      case OrchidConnectionState.VPNDisconnecting:
        warn = false;
        break;
      case OrchidConnectionState.VPNConnecting:
      case OrchidConnectionState.OrchidConnected:
      case OrchidConnectionState.VPNConnected:
        warn = true;
    }
    if (warnOnly && !warn) {
      return null;
    }
    var warning = warn ? s.changesWillTakeEffectInstruction : "";
    return AppDialogs.showAppDialog(
        context: context,
        title: s.saved + "!",
        bodyText: s.configurationSaved + " " + warning);
  }

  static void showConfigurationChangeFailed(BuildContext context,
      {String errorText}) {
    S s = S.of(context);
    AppDialogs.showAppDialog(
        context: context,
        title: s.whoops + "!",
        bodyText: s.configurationFailedInstruction +
            (errorText != null ? '\n\n' + errorText : ""));
  }
}
