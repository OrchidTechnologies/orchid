import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:orchid/common/app_colors.dart';
import 'package:orchid/common/app_text.dart';
import 'package:orchid/orchid/orchid_colors.dart';
import 'package:orchid/orchid/orchid_text.dart';

class AppDialogs {
  /// Show a styled Orchid app dialog with title, body, OK button, and optional link to settings.
  static Future<void> showAppDialog({
    @required BuildContext context,
    @required String title,
    String bodyText,
    Widget body,
    bool linkSettings = false,
    bool showActions = true,
  }) {
    S s = S.of(context);
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: OrchidColors.dark_background,
          // actionsPadding: EdgeInsets.zero,
          // buttonPadding: EdgeInsets.zero,
          // titlePadding: EdgeInsets.zero,
          // contentPadding: EdgeInsets.zero,
          // insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16.0))),
          title: Text(title, style: OrchidText.title),
          content: body ?? Text(bodyText, style: OrchidText.body2),
          actions: <Widget>[
            if (linkSettings)
              FlatButton(
                child: Text(s.settingsButtonTitle, style: AppText.dialogButton),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            if (showActions)
              FlatButton(
                child: Text(s.ok,
                    style:
                        OrchidText.button.copyWith(color: OrchidColors.purple_bright)),
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
          backgroundColor: OrchidColors.blue_highlight,
          title: title != null
              ? Text(
                  title,
                  style: OrchidText.subtitle.black,
                )
              : null,
          content: body ??
              Text(
                bodyText ?? s.confirmThisAction + "?",
                style: OrchidText.body2.black,
              ),
          actions: <Widget>[
            // CANCEL
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                side: BorderSide(color: OrchidColors.dark_background, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  cancelText ?? s.cancelButtonTitle,
                  style: OrchidText.button.black,
                ),
              ),
              onPressed: () {
                if (cancelAction != null) {
                  cancelAction();
                }
                Navigator.of(context).pop(false);
              },
            ),
            // ACTION
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                backgroundColor: OrchidColors.dark_background,
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  actionText ?? S.of(context).ok,
                  style: OrchidText.button,
                ),
              ),
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
