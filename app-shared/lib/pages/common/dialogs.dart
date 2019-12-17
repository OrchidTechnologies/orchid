import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:orchid/api/orchid_types.dart';
import 'package:orchid/pages/app_colors.dart';
import 'package:orchid/pages/app_text.dart';

class Dialogs {

  /// Show a styled Orchid app dialog with title, body, OK button, and optional link to settings.
  static Future<void> showAppDialog({
    @required BuildContext context,
    @required String title,
    @required String body,
    bool linkSettings = false,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          title: Text(title, style: AppText.dialogTitle),
          content: Text(body, style: AppText.dialogBody),
          actions: <Widget>[
            linkSettings
                ? FlatButton(
                    child: Text("SETTINGS", style: AppText.dialogButton),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/settings');
                    },
                  )
                : null,
            FlatButton(
              child: Text("OK", style: AppText.dialogButton),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static void showConfirmationDialog(
      {@required BuildContext context,
      String title,
      String body = "Confirm this action?",
      String cancelText = "CANCEL",
      Color cancelColor = AppColors.purple_3,
      actionText = "OK",
      Color actionColor = AppColors.purple_3,
      VoidCallback cancelAction,
      VoidCallback action}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))),
          title: title != null
              ? Text(title,
                  style:
                      AppText.dialogTitle.copyWith(color: AppColors.neutral_1))
              : null,
          content: Text(body,
              style: AppText.dialogBody.copyWith(color: AppColors.neutral_2)),
          actions: <Widget>[
            FlatButton(
              child: Text(cancelText,
                  style: AppText.dialogButton.copyWith(color: cancelColor)),
              onPressed: () {
                if (cancelAction != null) {
                  cancelAction();
                }
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text(actionText,
                  style: AppText.dialogButton.copyWith(color: actionColor)),
              onPressed: () {
                if (action != null) {
                  action();
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> showConfigurationChangeSuccess(BuildContext context, {bool warnOnly = false}) {
    var warn;
    switch(OrchidAPI().connectionStatus.value) {
      case OrchidConnectionState.Invalid:
      case OrchidConnectionState.NotConnected:
      case OrchidConnectionState.Disconnecting:
        warn = false;
        break;
      case OrchidConnectionState.Connecting:
      case OrchidConnectionState.Connected:
        warn = true;
    }
    if (warnOnly && !warn) {
      return null;
    }
    var warning = warn ? " Changes will take effect when the VPN is restarted." : "";
    return Dialogs.showAppDialog(
        context: context,
        title: "Saved!",
        body: "Configuration saved.$warning");
  }

  static void showConfigurationChangeFailed(BuildContext context) {
    Dialogs.showAppDialog(
        context: context,
        title: "Whoops!",
        body:
        "Configuration failed to save.  Please check syntax and try again.");
  }


}
