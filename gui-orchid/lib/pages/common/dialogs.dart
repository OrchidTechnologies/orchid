import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/generated/l10n.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';

class Dialogs {
  /// Show a styled Orchid app dialog with title, body, OK button, and optional link to settings.
  static Future<void> showAppDialog({
    @required BuildContext context,
    @required String title,
    String bodyText,
    Widget body,
    bool linkSettings = false,
  }) {
    S s = S.of(context);
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          title: Text(title, style: AppText.dialogTitle),
          content: body ?? Text(bodyText, style: AppText.dialogBody),
          actions: <Widget>[
            linkSettings
                ? FlatButton(
                    child: Text(s.settingsButtonTitle,
                        style: AppText.dialogButton),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/settings');
                    },
                  )
                : null,
            FlatButton(
              child: Text(s.ok, style: AppText.dialogButton),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<bool> showConfirmationDialog(
      {@required BuildContext context,
      String title,
      String body,
      String cancelText,
      Color cancelColor = AppColors.purple_3,
      actionText,
      Color actionColor = AppColors.purple_3,
      VoidCallback cancelAction,
      VoidCallback commitAction}) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        S s = S.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          title: title != null
              ? Text(title,
                  style:
                      AppText.dialogTitle.copyWith(color: AppColors.neutral_1))
              : null,
          content: Text(body ?? s.confirmThisAction + "?",
              style: AppText.dialogBody.copyWith(color: AppColors.neutral_2)),
          actions: <Widget>[
            FlatButton(
              child: Text(cancelText ?? s.cancelButtonTitle,
                  style: AppText.dialogButton.copyWith(color: cancelColor)),
              onPressed: () {
                if (cancelAction != null) {
                  cancelAction();
                }
                Navigator.of(context).pop(false);
              },
            ),
            FlatButton(
              child: Text(actionText ?? S.of(context).ok,
                  style: AppText.dialogButton.copyWith(color: actionColor)),
              onPressed: () {
                if (commitAction != null) {
                  commitAction();
                }
                Navigator.of(context).pop(true);
                return true;
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> showConfigurationChangeSuccess(BuildContext context,
      {bool warnOnly = false}) {
    S s = S.of(context);
    var warn;
    switch (OrchidAPI().connectionStatus.value) {
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.NotConnected:
      case OrchidConnectionState.Disconnecting:
        warn = false;
        break;
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.OrchidConnected:
      case OrchidConnectionState.VPNConnected:
        warn = true;
    }
    if (warnOnly && !warn) {
      return null;
    }
    var warning = warn ? s.changesWillTakeEffectInstruction : "";
    return Dialogs.showAppDialog(
        context: context,
        title: s.saved + "!",
        bodyText: s.configurationSaved + " " + warning);
  }

  static void showConfigurationChangeFailed(BuildContext context,
      {String errorText}) {
    S s = S.of(context);
    Dialogs.showAppDialog(
        context: context,
        title: s.whoops + "!",
        bodyText: s.configurationFailedInstruction +
            (errorText != null ? '\n\n' + errorText : ""));
  }
}
