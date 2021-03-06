import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_colors.dart';
import 'package:orchid/common/app_text.dart';

class AppDialogs {
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
              borderRadius: BorderRadius.all(Radius.circular(16.0))),
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
      Widget body,
      String bodyText,
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
          content: body ??
              Text(bodyText ?? s.confirmThisAction + "?",
                  style:
                      AppText.dialogBody.copyWith(color: AppColors.neutral_2)),
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
}
